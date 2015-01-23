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

package com.cognitect.transit.ruby.marshaler;

import java.io.OutputStream;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.TransitFactory;
import com.cognitect.transit.WriteHandler;

@JRubyClass(name="Transit::Marshaler::Json")
public class Json extends Base {
    private static final long serialVersionUID = 3453641906194326319L;

    public Json(final Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
    }

    /**
      args[0] - io   : any Ruby IO
      args[1] - opts : Ruby Hash
     **/
    @JRubyMethod(name="new", meta=true, required=1, rest=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        try {
            RubyClass rubyClass = (RubyClass)context.getRuntime().getClassFromPath("Transit::Marshaler::Json");
            Json json = (Json)rubyClass.allocate();
            json.callMethod(context, "initialize", args);
            json.init(context, args);
            return json;
        } catch (Throwable t) {
            t.printStackTrace();
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    private void init(ThreadContext context, IRubyObject[] args) {
        OutputStream output = convertRubyIOToOutputStream(context, args[0]);
        Map<Class, WriteHandler<?, ?>> handlers = convertRubyHandlersToJavaHandler(context, args[1]);
        writer = TransitFactory.writer(TransitFactory.Format.JSON, output, handlers);
    }

    @JRubyMethod
    public IRubyObject write(ThreadContext context, IRubyObject arg) {
        return super.write(context, arg);
    }
}
