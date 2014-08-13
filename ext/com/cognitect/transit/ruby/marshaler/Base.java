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
import org.jruby.RubyObject;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.WriteHandler;
import com.cognitect.transit.Writer;

public class Base extends RubyObject {
    private static final long serialVersionUID = -3179062656279837886L;
    protected Writer writer;

    public Base(Ruby runtime, RubyClass metaClass) {
        super(runtime, metaClass);
    }

    protected OutputStream convertRubyIOToOutputStream(ThreadContext context, IRubyObject rubyObject) {
        if (rubyObject.respondsTo("to_outputstream")) {
            return (OutputStream) rubyObject.callMethod(context, "to_outputstream").toJava(OutputStream.class);
        } else {
            throw rubyObject.getRuntime().newArgumentError("The first argument is not IO");
        }
    }

    protected Map<Class, WriteHandler<?, ?>> convertRubyHandlersToJavaHandlers(
            final ThreadContext context, IRubyObject rubyObject) {
        return null;
    }

    protected IRubyObject write(ThreadContext context, IRubyObject arg) {
        return null;
    }

}
