# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Transit
  # Transit::Writer marshals Ruby objects as transit values to an output stream.
  # @see https://github.com/cognitect/transit-format
  class Writer

    # @api private
    class Marshaler
      def initialize(opts)
        @cache_enabled  = !opts[:verbose]
        @prefer_strings = opts[:prefer_strings]
        @max_int        = opts[:max_int]
        @min_int        = opts[:min_int]

        handlers = WriteHandlers::DEFAULT_WRITE_HANDLERS.dup
        handlers = handlers.merge!(opts[:handlers]) if opts[:handlers]
        @handlers = (opts[:verbose] ? verbose_handlers(handlers) : handlers)
        @handlers.values.each do |h|
          if h.respond_to?(:handlers=)
            h.handlers=(@handlers)
          end
        end
      end

      def find_handler(obj)
        obj.class.ancestors.each do |a|
          if handler = @handlers[a]
            return handler
          end
        end
        nil
      end

      def verbose_handlers(handlers)
        handlers.each do |k, v|
          if v.respond_to?(:verbose_handler) && vh = v.verbose_handler
            handlers.store(k, vh.new)
          end
        end
        handlers
      end

      def escape(s)
        if s.start_with?(SUB,ESC,RES) && !s.start_with?("#{SUB}\s")
          "#{ESC}#{s}"
        else
          s
        end
      end

      def emit_nil(as_map_key, cache)
        as_map_key ? emit_string(ESC, "_", nil, true, cache) : emit_value(nil)
      end

      def emit_string(prefix, tag, value, as_map_key, cache)
        encoded = "#{prefix}#{tag}#{value}"
        if @cache_enabled && cache.cacheable?(encoded, as_map_key)
          emit_value(cache.write(encoded), as_map_key)
        else
          emit_value(encoded, as_map_key)
        end
      end

      def emit_boolean(handler, b, as_map_key, cache)
        as_map_key ? emit_string(ESC, "?", handler.string_rep(b), true, cache) : emit_value(b)
      end

      def emit_int(tag, i, as_map_key, cache)
        if as_map_key || i > @max_int || i < @min_int
          emit_string(ESC, tag, i, as_map_key, cache)
        else
          emit_value(i, as_map_key)
        end
      end

      def emit_double(d, as_map_key, cache)
        as_map_key ? emit_string(ESC, "d", d, true, cache) : emit_value(d)
      end

      def emit_array(a, cache)
        emit_array_start(a.size)
        a.each {|e| marshal(e, false, cache)}
        emit_array_end
      end

      def emit_map(m, cache)
        emit_map_start(m.size)
        m.each do |k,v|
          marshal(k, true, cache)
          marshal(v, false, cache)
        end
        emit_map_end
      end

      def emit_tagged_value(tag, rep, cache)
        emit_array_start(2)
        emit_string(ESC, "#", tag, false, cache)
        marshal(rep, false, cache)
        emit_array_end
      end

      def emit_encoded(handler, tag, obj, as_map_key, cache)
        if tag.length == 1
          rep = handler.rep(obj)
          if String === rep
            emit_string(ESC, tag, rep, as_map_key, cache)
          elsif as_map_key || @prefer_strings
            if str_rep = handler.string_rep(obj)
              emit_string(ESC, tag, str_rep, as_map_key, cache)
            else
              raise "Cannot be encoded as String: " + {:tag => tag, :rep => rep, :obj => obj}.to_s
            end
          else
            emit_tagged_value(tag, handler.rep(obj), cache)
          end
        elsif as_map_key
          raise "Cannot be used as a map key: " + {:tag => tag, :rep => rep, :obj => obj}.to_s
        else
          emit_tagged_value(tag, handler.rep(obj), cache)
        end
      end

      def marshal(obj, as_map_key, cache)
        handler = find_handler(obj)
        tag = handler.tag(obj)
        case tag
        when "_"
          emit_nil(as_map_key, cache)
        when "?"
          emit_boolean(handler, obj, as_map_key, cache)
        when "s"
          emit_string(nil, nil, escape(handler.rep(obj)), as_map_key, cache)
        when "i"
          emit_int(tag, handler.rep(obj), as_map_key, cache)
        when "d"
          emit_double(handler.rep(obj), as_map_key, cache)
        when "'"
          emit_tagged_value(tag, handler.rep(obj), cache)
        when "array"
          emit_array(handler.rep(obj), cache)
        when "map"
          emit_map(handler.rep(obj), cache)
        else
          emit_encoded(handler, tag, obj, as_map_key, cache)
        end
      end

      def marshal_top(obj, cache=RollingCache.new)
        if handler = find_handler(obj)
          if tag = handler.tag(obj)
            if tag.length == 1
              marshal(TaggedValue.new(QUOTE, obj), false, cache)
            else
              marshal(obj, false, cache)
            end
            flush
          else
            raise "Handler must provide a non-nil tag: #{handler.inspect}"
          end
        else
          raise "Can not find a Write Handler for #{obj.inspect}."
        end
      end
    end

    # @api private
    class BaseJsonMarshaler < Marshaler
      def default_opts
        {:prefer_strings => true,
          :max_int       => JSON_MAX_INT,
          :min_int       => JSON_MIN_INT}
      end

      def initialize(io, opts)
        @oj = Oj::StreamWriter.new(io)
        super(default_opts.merge(opts))
        @state = []
      end

      def emit_array_start(size)
        @state << :array
        @oj.push_array
      end

      def emit_array_end
        @state.pop
        @oj.pop
      end

      def emit_map_start(size)
        @state << :map
        @oj.push_object
      end

      def emit_map_end
        @state.pop
        @oj.pop
      end

      def emit_value(obj, as_map_key=false)
        if @state.last == :array
          @oj.push_value(obj)
        else
          as_map_key ? @oj.push_key(obj) : @oj.push_value(obj)
        end
      end

      def flush
        # no-op
      end
    end

    # @api private
    class JsonMarshaler < BaseJsonMarshaler
      def emit_map(m, cache)
        emit_array_start(-1)
        emit_value("^ ", false)
        m.each do |k,v|
          marshal(k, true, cache)
          marshal(v, false, cache)
        end
        emit_array_end
      end
    end

    # @api private
    class VerboseJsonMarshaler < BaseJsonMarshaler
      def emit_string(prefix, tag, value, as_map_key, cache)
        emit_value("#{prefix}#{tag}#{value}", as_map_key)
      end

      def emit_tagged_value(tag, rep, cache)
        emit_map_start(1)
        emit_string(ESC, "#", tag, true, cache)
        marshal(rep, false, cache)
        emit_map_end
      end
    end

    # @api private
    class MessagePackMarshaler < Marshaler
      def default_opts
        {:prefer_strings => false,
          :max_int       => MAX_INT,
          :min_int       => MIN_INT}
      end

      def initialize(io, opts)
        @io = io
        @packer = MessagePack::Packer.new(io)
        super(default_opts.merge(opts))
      end

      def emit_array_start(size)
        @packer.write_array_header(size)
      end

      def emit_array_end
        # no-op
      end

      def emit_map_start(size)
        @packer.write_map_header(size)
      end

      def emit_map_end
        # no-op
      end

      def emit_value(obj, as_map_key=:ignore)
        @packer.write(obj)
      end

      def flush
        @packer.flush
        @io.flush
      end
    end

    # @param [Symbol] type, required either :msgpack or :json
    # @param [IO]     io, required
    # @param [Hash]   opts, optional
    def initialize(type, io, opts={})
      @marshaler = case type
                   when :json
                     require 'oj'
                     JsonMarshaler.new(io,
                                       {:prefer_strings => true,
                                        :verbose        => false,
                                        :handlers       => {}}.merge(opts))
                   when :json_verbose
                     require 'oj'
                     VerboseJsonMarshaler.new(io,
                                              {:prefer_strings => true,
                                               :verbose        => true,
                                               :handlers       => {}}.merge(opts))
                   else
                     require 'msgpack'
                     MessagePackMarshaler.new(io,
                                              {:prefer_strings => false,
                                               :verbose        => false,
                                               :handlers       => {}}.merge(opts))
                   end
    end

    # Converts a Ruby object to a transit value and writes it to this
    # Writer's output stream.
    #
    # @param obj the value to write
    def write(obj)
      @marshaler.marshal_top(obj)
    end
  end
end
