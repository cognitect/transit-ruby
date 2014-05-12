# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class TransitMarshaler < Marshaler
    class HashWrapper
      extend Forwardable
      def_delegators :@h, :[], :[]=
      attr_reader :h
      def initialize; @h = {}; end
    end

    TRANSIT_MAX_INT = JsonMarshaler::JSON_MAX_INT
    TRANSIT_MIN_INT = JsonMarshaler::JSON_MIN_INT

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
end
