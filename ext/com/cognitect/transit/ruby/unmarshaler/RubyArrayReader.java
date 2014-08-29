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
import org.jruby.RubyArray;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.ArrayReader;
import com.cognitect.transit.ruby.TransitTypeConverter;

public class RubyArrayReader implements ArrayReader<RubyArray, IRubyObject, Object> {
    private Ruby runtime;

    public RubyArrayReader(Ruby runtime) {
        this.runtime = runtime;
    }

    @Override
    public RubyArray add(RubyArray array, Object item) {
        IRubyObject value;
        if (TransitTypeConverter.needsCostomConverter(item)) {
            value = TransitTypeConverter.convertStringToFloat(runtime, item);
        } else {
            value = JavaUtil.convertJavaToUsableRubyObject(runtime, item);
        }
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
