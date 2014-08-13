package com.cognitect.transit.ruby;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.ArrayReader;

public class RubyArrayReader implements ArrayReader<RubyArray, IRubyObject, Object> {
    private Ruby runtime;

    public RubyArrayReader(Ruby runtime) {
        this.runtime = runtime;
    }

    @Override
    public RubyArray add(RubyArray array, Object item) {
        JavaUtil.JavaConverter converter = TransitTypeConverters.converter(item);
        IRubyObject value = JavaUtil.convertJavaToUsableRubyObjectWithConverter(runtime, item, converter);
        array.callMethod(array.getRuntime().getCurrentContext(), "<<", value);
        return array;
    }

    @Override
    public RubyArray complete(RubyArray array) {
        return array;
    }

    @Override
    public RubyArray init() {
        return runtime.newArray();
    }

    @Override
    public RubyArray init(int size) {
        return runtime.newArray(size);
    }
}
