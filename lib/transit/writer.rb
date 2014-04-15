require 'oj'
require 'msgpack'

module Transit
  class Marshaler
    def initialize(opts={})
      @opts = opts
      @handlers = Handler.new
    end

    def register(type, handler_class)
      @handlers[type] = handler_class.new
    end

    def escape(s)
      return s if [nil, true, false].include? s
      [ESC, SUB, RES].include?(s[0]) ? "#{ESC}#{s}" : s
    end

    def stringable_keys?(m)
      # TODO - handler keys that have no handler
      m.keys.all? {|k| (@handlers[k].tag(k).length == 1) }
    end

    def emit_nil(_, as_map_key, cache)
      as_map_key ? emit_string(ESC, "_", nil, true, cache) : emit_object(nil)
    end

    def emit_string(prefix, tag, string, as_map_key, cache)
      str = "#{prefix}#{tag}#{escape(string)}"
      if cache.cacheable?(str, as_map_key)
        emit_object(cache.encode(str, as_map_key), as_map_key)
      else
        emit_object(str, as_map_key)
      end
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
      emit_object("~#cmap", true)
      marshal(m.reduce([]) {|a, kv| a.concat(kv)}, false, cache)
      emit_map_end
    end

    def emit_tagged_map(tag, rep, _, cache)
      emit_map_start(1)
      emit_object("#{ESC}##{tag}", true)
      marshal(rep, false, cache)
      emit_map_end
    end

    def emit_encoded(tag, handler, obj, as_map_key, cache)
      if tag
        if tag.length == 1
          rep = handler.rep(obj)
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
          emit_tagged_map(tag, handler.rep(obj), false, cache)
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
        if stringable_keys?(rep)
          emit_map(rep, as_map_key, cache)
        else
          emit_cmap(rep, as_map_key, cache)
        end
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
      end
    end
  end

  class JsonMarshaler < Marshaler
    JSON_MAX_INT = 2**53 - 1
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

  class MessagePackMarshaler < Marshaler
    MSGPACK_MAX_INT = 2**63 - 1
    MSGPACK_MIN_INT = -2**63

    def default_opts
      {:prefer_strings => false,
        :max_int       => MSGPACK_MAX_INT,
        :min_int       => MSGPACK_MIN_INT}
    end

    def initialize(io, opts={})
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
    end
  end

  class TransitMarshaler < Marshaler
    class HashWrapper
      extend Forwardable
      def_delegators :@h, :[], :[]=
      attr_reader :h
      def initialize; @h = {}; end
    end

    TRANSIT_MAX_INT = 2**63 - 1
    TRANSIT_MIN_INT = -2**63

    def default_opts
      {:prefer_strings => true,
        :max_int       => TRANSIT_MAX_INT,
        :min_int       => TRANSIT_MIN_INT}
    end

    attr_reader :value

    def initialize(opts={})
      @value = nil
      @stack = []
      @keys = {}
      super(default_opts.merge(opts))
    end

    def emit_array_start(size)
      @stack.push([])
    end

    def emit_array_end
      o = @stack.pop
      if @stack.empty?
        @value = o
      else
        emit_object(o)
      end
    end

    def emit_map_start(size)
      h = HashWrapper.new
      @stack.push(h)
      @keys[h] = []
    end

    def emit_map_end
      o = @stack.pop.h
      if @stack.empty?
        @value = o
      else
        emit_object(o)
      end
    end

    def emit_object(obj, as_map_key=false)
      current = @stack.last
      if Array === current
        current.push(obj)
      elsif HashWrapper === current
        if @keys[current].empty?
          @keys[current].push(obj)
        else
          current[@keys[current].pop] = obj
        end
      else
        @value = obj
      end
    end

    def flush
      # no-op
    end
  end

  class Writer
    def initialize(io, type)
      @marshaler = if type == :json
                     JsonMarshaler.new(io, :quote_scalars => true, :prefer_strings => true)
                   else
                     MessagePackMarshaler.new(io, :quote_scalars => false, :prefer_strings => false)
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
