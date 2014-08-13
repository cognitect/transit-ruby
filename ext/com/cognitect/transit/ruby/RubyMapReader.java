package com.cognitect.transit.ruby;

import org.jruby.Ruby;
import org.jruby.RubyHash;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.MapReader;

public class RubyMapReader implements MapReader<RubyHash, RubyHash, Object, Object> {
    private Ruby runtime;
    
    public RubyMapReader(Ruby runtime) {
        this.runtime = runtime;
    }

    @Override
    public RubyHash add(RubyHash hash, Object key, Object value) {
        JavaUtil.JavaConverter key_converter = TransitTypeConverters.converter(key);
        JavaUtil.JavaConverter value_converter = TransitTypeConverters.converter(value);
        IRubyObject key_value = JavaUtil.convertJavaToUsableRubyObjectWithConverter(runtime, key, key_converter);
        IRubyObject value_value = JavaUtil.convertJavaToUsableRubyObjectWithConverter(runtime, value, value_converter);
        IRubyObject[] args = new IRubyObject[]{key_value, value_value};
        hash.callMethod(runtime.getCurrentContext(), "[]=", args);
        return hash;
    }

    @Override
    public RubyHash complete(RubyHash hash) {
        return hash;
    }

    @Override
    public RubyHash init() {
        return RubyHash.newHash(runtime);
    }

    @Override
    public RubyHash init(int size) {
        return RubyHash.newHash(runtime);
    }

}
