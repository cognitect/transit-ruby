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
import java.util.HashMap;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.DefaultReadHandler;
import com.cognitect.transit.ReadHandler;
import com.cognitect.transit.Reader;
import com.cognitect.transit.impl.ReaderFactory;

public abstract class Base extends RubyObject {
    private static final long serialVersionUID = -2693178195157618851L;
    protected Reader reader;

    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

    public Base(final Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
    }
    
    protected static IRubyObject newDecoder(ThreadContext context, IRubyObject opts) {
        RubyClass decoderClass = (RubyClass) context.getRuntime().getClassFromPath("Transit::Decoder");
        return decoderClass.callMethod(context, "new", opts);
    }

    protected InputStream convertRubyIOToInputStream(ThreadContext context, IRubyObject rubyObject) {
        if (rubyObject.respondsTo("to_inputstream")) {
            return (InputStream) rubyObject.callMethod(context, "to_inputstream").toJava(InputStream.class);
        } else {
            throw rubyObject.getRuntime().newArgumentError("The first argument is not IO");
        }
    }

    protected Map<String, ReadHandler<?, ?>> convertRubyHandlersToJavaHandlers(
            final ThreadContext context) {
        IRubyObject decoder = this.getInstanceVariable("@decoder");
        IRubyObject ivar = decoder.callMethod(context.getRuntime().getCurrentContext(), "instance_variable_get", context.getRuntime().newString("@handlers"));
        final RubyHash handlers = (RubyHash)ivar;
        Map<String, ReadHandler<?, ?>> javaHandlers = new HashMap<String, ReadHandler<?, ?>>();
        for (Object key : handlers.keySet()) {
            final IRubyObject handler = (IRubyObject)handlers.get(key);
            javaHandlers.put((String)key, new ReadHandler<IRubyObject, Object>() {
                public IRubyObject fromRep(Object o) {
                    return handler.callMethod(context, "from_rep",
                            JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), o));
                }
            });
        }
        // replaces TimeStringHandler to cover JRuby's bug in DateTime.iso8601() method
        if (((RubyObject)handlers.get("t")).getMetaClass().getName().
                equals("Transit::ReadHandlers::TimeStringHandler")) {
            javaHandlers.put("t", new ReadHandler<IRubyObject, Object>() {
                public IRubyObject fromRep(Object o) {
                    RubyClass klazz = (RubyClass) context.getRuntime().getClassFromPath("DateTime");
                    RubyString string = context.getRuntime().newString((String)o);
                    RubyString format = context.getRuntime().newString("%Y-%m-%dT%H:%M:%S.%N%z");
                    return klazz.callMethod(context, "strptime", new IRubyObject[]{string, format});
                }
            });
        }
        return javaHandlers;
    }

    protected DefaultReadHandler<IRubyObject> convertRubyDefaultHandlerToJavaDefaultHandler(
            final ThreadContext context) {
        IRubyObject decoder = this.getInstanceVariable("@decoder");
        IRubyObject ivar = decoder.callMethod(context.getRuntime().getCurrentContext(),
                    "instance_variable_get",
                    context.getRuntime().newString("@default_handler"));
        final RubyObject handler = (RubyObject)ivar;
        DefaultReadHandler<IRubyObject> javaHandler = new DefaultReadHandler<IRubyObject>() {
            public IRubyObject fromRep(String tag, Object rep) {
                return handler.callMethod("from_rep",
                        context.getRuntime().newString(tag),
                        JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), rep));
            }
        };
        return javaHandler;
    }

    /**
       read method accepts a block
     **/
    protected IRubyObject read(ThreadContext context, Block block) {
        try {
            Object o;
            while ((o = reader.read()) != null) {
                IRubyObject value;
                if (o instanceof IRubyObject) {
                    value = (IRubyObject)o;
                } else {
                    value = JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), o);
                }
                if ((value != null) && block.isGiven()) {
                    block.yield(context, value);
                } else {
                    return value;
                }
            }
            return context.getRuntime().getNil();
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }
}
