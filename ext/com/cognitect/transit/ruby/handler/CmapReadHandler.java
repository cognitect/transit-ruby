package com.cognitect.transit.ruby.handler;

import java.util.HashMap;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyHash;

import com.cognitect.transit.ArrayReadHandler;
import com.cognitect.transit.ArrayReader;

public class CmapReadHandler implements ArrayReadHandler<Object, RubyHash, Object, Object> {
    private Ruby runtime;

    public CmapReadHandler(Ruby runtime) {
        this.runtime = runtime;
    }

    @Override
    public RubyHash fromRep(Object arg0) {
        throw runtime.newNotImplementedError("will implement if necessary");
    }

    @Override
    public ArrayReader<Object, RubyHash, Object> arrayReader() {
        return new ArrayReader<Object, RubyHash, Object>() {
            Map<Object, Object> m = null;
            Object next_key = null;

            @Override
            public Object add(Object arg0, Object item) {
                if (next_key != null) {
                    m.put(next_key, item);
                    next_key = null;
                } else {
                    next_key = item;
                }
                return this;
            }

            @Override
            public RubyHash complete(Object arg0) {
                RubyHash hash = RubyHash.newHash(runtime);
                hash.putAll(m);
                return hash;
            }

            @Override
            public Object init() {
                return init(16);
            }

            @Override
            public Object init(int size) {
                m = new HashMap<Object, Object>(size);
                return this;
            }
        };
    }
}
