# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class Marshaler
    def initialize(opts={})
      @opts = opts
      @handlers = (@opts[:verbose] ? verbose_handlers(Handlers.new) : Handlers.new)
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

    def register(type, handler_class)
      @handlers[type] = handler_class.new
    end

    def escape(s)
      if s.nil?
        s
      elsif s.start_with?("#{RES}#{ESC}")
        s[1..-1]
      elsif s.start_with?(SUB,ESC,RES) && !s.start_with?("#{SUB}\s")
        "#{ESC}#{s}"
      else
        s
      end
    end

    def stringable_keys?(m)
      m.keys.all? {|k| (@handlers[k].tag(k).length == 1) }
    end

    def emit_nil(_, as_map_key, cache)
      as_map_key ? emit_string(ESC, "_", nil, true, cache) : emit_object(nil)
    end

    def emit_string(prefix, tag, string, as_map_key, cache)
      emit_object(cache.encode("#{prefix}#{tag}#{escape(string)}", as_map_key), as_map_key)
    end

    def emit_boolean(b, as_map_key, cache)
      as_map_key ? emit_string(ESC, "?", b, true, cache) : emit_object(b)
    end

    def emit_quoted(o, as_map_key, cache)
      emit_map_start(1)
      emit_string(TAG, "'", nil, true, cache)
      marshal(o, false, cache)
      emit_map_end
    end

    def emit_int(i, as_map_key, cache)
      if as_map_key || i > @opts[:max_int] || i < @opts[:min_int]
        emit_string(ESC, "i", i.to_s, as_map_key, cache)
      else
        emit_object(i, as_map_key)
      end
    end

    def emit_bigint(i, as_map_key, cache)
      if as_map_key || i > @opts[:max_int] || i < @opts[:min_int]
        emit_string(ESC, "n", i.to_s, as_map_key, cache)
      else
        emit_object(i, as_map_key)
      end
    end

    def emit_double(d, as_map_key, cache)
      as_map_key ? emit_string(ESC, "d", d, true, cache) : emit_object(d)
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

    def emit_cmap(m, _, cache)
      emit_map_start(1)
      emit_string(ESC, "#", "cmap", true, cache)
      marshal(m.reduce([]) {|a, kv| a.concat(kv)}, false, cache)
      emit_map_end
    end

    def emit_tagged_map(tag, rep, _, cache)
      emit_map_start(1)
      emit_string(ESC, "#", tag, true, cache)
      marshal(rep, false, cache)
      emit_map_end
    end

    def emit_encoded(tag, handler, obj, as_map_key, cache)
      rep = handler.rep(obj)
      if tag.length == 1
        if String === rep
          emit_string(ESC, tag, rep, as_map_key, cache)
        elsif as_map_key || @opts[:prefer_strings]
          rep = handler.string_rep(obj)
          if String === rep
            emit_string(ESC, tag, rep, as_map_key, cache)
          else
            raise "Cannot be encoded as String: " + {:tag => tag, :rep => rep, :obj => obj}.to_s
          end
        else
          emit_tagged_map(tag, rep, false, cache)
        end
      elsif as_map_key
        raise "Cannot be used as a map key: " + {:tag => tag, :rep => rep, :obj => obj}.to_s
      else
        emit_tagged_map(tag, rep, false, cache)
      end
    end

    def marshal(obj, as_map_key, cache)
      handler = @handlers[obj]
      tag = handler.tag(obj)
      rep = as_map_key ? handler.string_rep(obj) : handler.rep(obj)
      case tag
      when "_"
        emit_nil(rep, as_map_key, cache)
      when "?"
        emit_boolean(rep, as_map_key, cache)
      when "s"
        emit_string(nil, nil, rep, as_map_key, cache)
      when "i"
        emit_int(rep, as_map_key, cache)
      when "n"
        emit_bigint(rep, as_map_key, cache)
      when "d"
        emit_double(rep, as_map_key, cache)
      when "'"
        emit_quoted(rep, as_map_key, cache)
      when "array"
        emit_array(rep, as_map_key, cache)
      when "map"
        emit_map(rep, as_map_key, cache)
      else
        emit_encoded(tag, handler, obj, as_map_key, cache)
      end
    end

    def marshal_top(obj, cache=RollingCache.new)
      handler = @handlers[obj]
      if tag = handler.tag(obj)
        if @opts[:quote_scalars] && tag.length == 1
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
    # see http://ecma262-5.com/ELS5_HTML.htm#Section_8.5
    JSON_MAX_INT = 2**53
    JSON_MIN_INT = -2**53

    def default_opts
      {:prefer_strings => true,
        :max_int       => JSON_MAX_INT,
        :min_int       => JSON_MIN_INT}
    end

    def initialize(io, opts={})
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

    def emit_object(obj, as_map_key=false)
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
    def emit_string(prefix, tag, string, as_map_key, cache)
      emit_object("#{prefix}#{tag}#{escape(string)}", as_map_key)
    end
  end

  class MessagePackMarshaler < Marshaler
    MSGPACK_MAX_INT = 2**63-1
    MSGPACK_MIN_INT = -2**63

    def default_opts
      {:prefer_strings => false,
        :max_int       => MSGPACK_MAX_INT,
        :min_int       => MSGPACK_MIN_INT}
    end

    def initialize(io, opts={})
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

    def emit_object(obj, as_map_key=:ignore)
      @packer.write(obj)
    end

    def flush
      @packer.flush
      @io.flush
    end
  end

  class Writer
    def initialize(type, io)
      @marshaler = case type
                   when :json
                     require 'oj'
                     JsonMarshaler.new(io,
                                       :quote_scalars  => true,
                                       :prefer_strings => true,
                                       :verbose        => false)
                   when :json_verbose
                     require 'oj'
                     VerboseJsonMarshaler.new(io,
                                              :quote_scalars  => true,
                                              :prefer_strings => true,
                                              :verbose        => true)
                   else
                     require 'msgpack'
                     MessagePackMarshaler.new(io,
                                              :quote_scalars  => false,
                                              :prefer_strings => false,
                                              :verbose        => false)
                   end
    end

    def write(obj)
      @marshaler.marshal_top(obj)
    end

    def register(type, handler_class)
      @marshaler.register(type, handler_class)
    end
  end
end
