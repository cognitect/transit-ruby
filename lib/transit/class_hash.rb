# Copyright (c) Cognitect, Inc.
# All rights reserved.

module Transit
  class ClassHash
    extend Forwardable

    def_delegators :@values, :[]=, :size, :each, :store, :keys, :values

    def initialize
      @values = {}
    end

    def [](clazz)
      clazz.ancestors.each do |a|
        if val = @values[a]
          return val
        end
      end
      nil
    end
  end
end
