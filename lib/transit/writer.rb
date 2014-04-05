require 'oj'

module Transit
  class JsonMarshaler

    def initialize(io)
      @oj = Oj::StreamWriter.new(io)
      @handlers = Handler.new
    end

    def escape(s)
      return s if [nil, true, false].include? s
      [ESC, SUB, RES].include?(s[0]) ? "#{ESC}#{s}" : s
    end

    def push(obj, as_map_key)
      as_map_key ? @oj.push_key(obj) : @oj.push_value(obj)
    end

    def emit_nil(_, as_map_key, cache)
      as_map_key ? emit_string(ESC, "_", nil, true, cache) : @oj.push_value(nil)
    end

    def emit_string(prefix, tag, string, as_map_key, cache)
      str = "#{prefix}#{tag}#{escape(string)}"
      if cache.cacheable?(str, as_map_key)
        push(cache.encode(str, as_map_key), as_map_key)
      else
        push(str, as_map_key)
      end
    end

    def emit_boolean(b, as_map_key, cache)
      as_map_key ? emit_string(ESC, "?", b, true, cache) : @oj.push_value(b)
    end

    def emit_quoted(o, as_map_key, cache)
      emit_map_start
      emit_string(TAG, "'", nil, true, cache)
      marshal(o, false, cache)
      emit_map_end
    end

    MAX_INT = 2**53 - 1

    def emit_int(i, as_map_key, cache)
      if as_map_key || i > MAX_INT
        emit_string(ESC, "i", i.to_s, as_map_key, cache)
      else
        push(i, as_map_key)
      end
    end

    def emit_double(d, as_map_key, cache)
      as_map_key ? emit_string(ESC, "d", d, true, cache) : @oj.push_value(d)
    end

    def emit_array(a, _, cache)
      @oj.push_array
      a.each {|e| marshal(e, false, cache)}
      @oj.pop
    end

    def emit_map_start
      @oj.push_object
    end

    def emit_map_end
      @oj.pop
    end

    def emit_map(m, _, cache)
      emit_map_start
      m.each do |k,v|
        marshal(k, true, cache)
        marshal(v, false, cache)
      end
      emit_map_end
    end

    def emit_tagged_map(tag, rep, _, cache)
      @oj.push_object
      @oj.push_key("#{ESC}##{tag}")
      marshal(rep, false, cache)
      @oj.pop
    end

    def emit_encoded(tag, obj, as_map_key, cache)
      if tag
        handler = @handlers[obj]
        if String === rep = handler.rep(obj)
          emit_string(ESC, tag, rep, as_map_key, cache)
        else
          emit_tagged_map(tag, rep.rep, false, cache)
        end
      end
    end

    def marshal(obj, as_map_key, cache)
      handler = @handlers[obj]
      tag = handler.tag(obj)
      rep = as_map_key ? handler.string_rep(obj) : handler.rep(obj)
      case tag
      when "s"
        emit_string(nil, nil, rep, as_map_key, cache)
      when "'"
        emit_quoted(rep, as_map_key, cache)
      when "i"
        emit_int(rep, as_map_key, cache)
      when "d"
        emit_double(rep, as_map_key, cache)
      when "_"
        emit_nil(rep, as_map_key, cache)
      when "?"
        emit_boolean(rep, as_map_key, cache)
      when :array
        emit_array(rep, as_map_key, cache)
      when :map
        emit_map(rep, as_map_key, cache)
      else
        emit_encoded(tag, obj, as_map_key, cache)
      end
    end

    def marshal_top(obj, cache)
      handler = @handlers[obj]
      if tag = handler.tag(obj)
        marshal(tag.length == 1 ? Quote.new(obj) : obj, false, cache)
      end
    end
  end

  class Writer
    def initialize(io, type)
      @marshaler = JsonMarshaler.new(io)
    end

    def write(obj)
      @marshaler.marshal_top(obj, RollingCache.new)
    end
  end
end
