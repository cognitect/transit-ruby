module Transit
  class ClassHash
    extend Forwardable

    def_delegators :@values, :[]=, :size, :each

    def initialize
      @values = {}
    end

    def [](clazz)
      clazz.ancestors.each do |a|
        return @values[a] if @values[a]
      end
      nil
    end

    def values
      @values.values
    end
  end
end
