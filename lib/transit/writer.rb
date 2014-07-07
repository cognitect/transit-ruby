# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class Marshaler
    def initialize(opts)
      @cache_enabled  = !opts[:verbose]
      @quote_scalars  = opts[:quote_scalars]
      @prefer_strings = opts[:prefer_strings]
      @max_int        = opts[:max_int]
      @min_int        = opts[:min_int]

      handlers = WriteHandlers.new(opts[:handlers])
      @handlers = (opts[:verbose] ? verbose_handlers(handlers) : handlers)
      @handlers.values.each do |h|
        if h.respond_to?(:handlers=)
          h.handlers=(@handlers)
        end
      end
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
      if s.start_with?("#{RES}#{ESC}")
        s[1..-1]
      elsif s.start_with?(SUB,ESC,RES) && !s.start_with?("#{SUB}\s")
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

    def emit_quoted(o, as_map_key, cache)
      emit_map_start(1)
      emit_string(TAG, "'", nil, true, cache)
      marshal(o, false, cache)
      emit_map_end
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

    def emit_array(a, _, cache)
      emit_array_start(a.size)
      a.each {|e| marshal(e, false, cache)}
      emit_array_end
    end

    def emit_map(m, _, cache)
      emit_map_start(m.size)
      m.each do |k,v|
        marshal(k, true, cache)
        marshal(v, false, cache)
      end
      emit_map_end
    end

    def emit_tagged_map(tag, rep, cache)
      emit_map_start(1)
      emit_string(ESC, "#", tag, true, cache)
      marshal(rep, false, cache)
      emit_map_end
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
          emit_tagged_map(tag, handler.rep(obj), cache)
        end
      elsif as_map_key
        raise "Cannot be used as a map key: " + {:tag => tag, :rep => rep, :obj => obj}.to_s
      else
        emit_tagged_map(tag, handler.rep(obj), cache)
      end
    end

    def marshal(obj, as_map_key, cache)
      handler = @handlers[obj]
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
        emit_quoted(handler.rep(obj), as_map_key, cache)
      when "array"
        emit_array(handler.rep(obj), as_map_key, cache)
      when "map"
        emit_map(handler.rep(obj), as_map_key, cache)
      else
        emit_encoded(handler, tag, obj, as_map_key, cache)
      end
    end

    def marshal_top(obj, cache=RollingCache.new)
      handler = @handlers[obj]
      if tag = handler.tag(obj)
        if @quote_scalars && tag.length == 1
          marshal(Quote.new(obj), false, cache)
        else
          marshal(obj, false, cache)
        end
        flush
      else
        raise "Handler must provide a non-nil tag: #{handler.inspect}"
      end
    end
  end

  class BaseJsonMarshaler < Marshaler
    def default_opts
      {:prefer_strings => true,
        :max_int       => JSON_MAX_INT,
        :min_int       => JSON_MIN_INT}
    end

    def initialize(io, opts)
      @oj = Oj::StreamWriter.new(io)
      super(default_opts.merge(opts))
    end

    def emit_array_start(size)
      @oj.push_array
    end

    def emit_array_end
      @oj.pop
    end

    def emit_map_start(size)
      @oj.push_object
    end

    def emit_map_end
      @oj.pop
    end

    def emit_value(obj, as_map_key=false)
      as_map_key ? @oj.push_key(obj) : @oj.push_value(obj)
    end

    def flush
      # no-op
    end
  end

  class JsonMarshaler < BaseJsonMarshaler
    def emit_map(m, _, cache)
      emit_array(["^ ", *m.flat_map{|x|x}], _, cache)
    end
  end

  class VerboseJsonMarshaler < BaseJsonMarshaler
    def emit_string(prefix, tag, value, as_map_key, cache)
      emit_value("#{prefix}#{tag}#{value}", as_map_key)
    end
  end

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

  # Transit::Writer marshals Ruby objects as transit values to an output stream.
  # @see https://github.com/cognitect/transit-format
  class Writer

    # @param [Symbol] type, required either :msgpack or :json
    # @param [IO]     io, required
    # @param [Hash]   opts, optional
    def initialize(type, io, opts={})
      @marshaler = case type
                   when :json
                     require 'oj'
                     JsonMarshaler.new(io,
                                       {:quote_scalars  => true,
                                        :prefer_strings => true,
                                        :verbose        => false,
                                        :handlers       => {}}.merge(opts))
                   when :json_verbose
                     require 'oj'
                     VerboseJsonMarshaler.new(io,
                                              {:quote_scalars  => true,
                                               :prefer_strings => true,
                                               :verbose        => true,
                                               :handlers       => {}}.merge(opts))
                   else
                     require 'msgpack'
                     MessagePackMarshaler.new(io,
                                              {:quote_scalars  => false,
                                               :prefer_strings => false,
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
