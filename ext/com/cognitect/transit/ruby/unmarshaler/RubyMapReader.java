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

package com.cognitect.transit.ruby.unmarshaler;

import org.jruby.Ruby;
import org.jruby.RubyHash;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.MapReader;
import com.cognitect.transit.ruby.TransitTypeConverter;

public class RubyMapReader implements MapReader<RubyHash, RubyHash, Object, Object> {
    private Ruby runtime;

    public RubyMapReader(Ruby runtime) {
        this.runtime = runtime;
    }

    @Override
    public RubyHash add(RubyHash hash, Object key, Object value) {
        IRubyObject ruby_key = convertJavaToRuby(key);
        IRubyObject ruby_value = convertJavaToRuby(value);
        IRubyObject[] args = new IRubyObject[]{ruby_key, ruby_value};
        hash.callMethod(runtime.getCurrentContext(), "[]=", args);
        return hash;
    }

    private IRubyObject convertJavaToRuby(Object o) {
        if (TransitTypeConverter.needsCostomConverter(o)) {
            return TransitTypeConverter.convertStringToFloat(runtime, o);
        } else {
            return JavaUtil.convertJavaToUsableRubyObject(runtime, o);
        }
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
