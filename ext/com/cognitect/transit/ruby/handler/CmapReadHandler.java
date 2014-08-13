// Copyright 2014 Cognitect. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS-IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
// implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
