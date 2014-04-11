module Transit
  class JsonEmitter
    def initialize(io)
      @oj = Oj::StreamWriter.new(io)
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

  class MessagePackEmitter
    def initialize(io)
      @packer = MessagePack::Packer.new(io)
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

  class TransitEmitter
    class HashWrapper
      extend Forwardable
      def_delegators :@h, :[], :[]=
      attr_reader :h
      def initialize; @h = {}; end
    end

    attr_reader :value

    def initialize
      @value = nil
      @stack = []
      @keys = {}
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
end
