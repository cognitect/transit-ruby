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

import java.io.InputStream;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.ReadHandler;
import com.cognitect.transit.TransitFactory;

@JRubyClass(name="Transit::Unmarshaler::Json")
public class Json extends Base {
    private static final long serialVersionUID = -6605166968548176488L;

    public Json(final Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
    }

    /**
       args[0] - io   : any Ruby IO
       args[1] - opts : Ruby Hash
     **/
    @JRubyMethod(name="new", meta=true, required=1, rest=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        RubyClass rubyClass = (RubyClass)context.getRuntime().getClassFromPath("Transit::Unmarshaler::Json");
        Json json = (Json)rubyClass.allocate();
        json.init(context, args);
        return json;
    }

    private void init(ThreadContext context, IRubyObject[] args) {
        InputStream input = convertRubyIOToInputStream(context, args[0]);
        Map<String, ReadHandler> handlers = convertRubyHandlersToJavaHandlers(context, args[1]);
        if (handlers == null) {
            reader = TransitFactory.reader(TransitFactory.Format.JSON, input);
        } else {
            reader = TransitFactory.reader(TransitFactory.Format.JSON, input, handlers);
        }
    }

    /**
       read method accepts a block
     **/
    @JRubyMethod
    public IRubyObject read(ThreadContext context, Block block) {
        return super.read(context, block);
    }
}
