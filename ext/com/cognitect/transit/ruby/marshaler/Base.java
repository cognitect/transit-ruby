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
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.WriteHandler;
import com.cognitect.transit.Writer;

public class Base extends RubyObject {
    private static final long serialVersionUID = -3179062656279837886L;
    protected Writer<Object> writer;

    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }

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

    /**
     * Converts the handlers defined in Ruby to java and wraps them in a single java handler
     * that delegates to the correct handler. Assumes that @handlers includes custom handlers
     * and any verbose handlers.
     */
    protected Map<Class, WriteHandler<?, ?>> convertRubyHandlersToJavaHandler(
            final ThreadContext context,
            IRubyObject arg) {
        Map<Class, WriteHandler<?, ?>> result = new HashMap<Class, WriteHandler<?, ?>>(1);
        RubyHash rubyHandlers = (RubyHash)this.getInstanceVariable("@handlers");
        final Map<String, WriteHandler<Object, Object>> javaHandlers = new HashMap<String, WriteHandler<Object, Object>>();

        for (Map.Entry entry : (Set<Map.Entry>)rubyHandlers.entrySet()) {
            javaHandlers.put(((RubyModule)entry.getKey()).getName(),
                    convertRubyToJava(context, (RubyObject)entry.getValue()));
        }
        result.put(RubyObject.class, new WriteHandler<Object, Object>() {
            @Override
            public <V> WriteHandler<Object, V> getVerboseHandler() {
                return null;
            }

            private WriteHandler<Object, Object> findHandler(Object o) {
                if (o instanceof RubyObject) {
                    RubyArray ancestors = (RubyArray)((RubyObject)o).getMetaClass().callMethod(context, "ancestors");
                    for (Object ancestor : ancestors) {
                        WriteHandler<Object, Object> handler = javaHandlers.get(((RubyModule)ancestor).getName());
                        if (handler != null) return handler;
                    }
                }
                return null;
            }

            @Override
            public Object rep(Object o) {
                WriteHandler<Object, Object> handler = findHandler(o);
                if (handler != null) return handler.rep(o);
                return null;
            }

            @Override
            public String stringRep(Object o) {
                WriteHandler<Object, Object> handler = findHandler(o);
                if (handler != null) return handler.stringRep(o);
                return null;
            }

            @Override
            public String tag(Object o) {
                WriteHandler<Object, Object> handler = findHandler(o);
                if (handler != null) return handler.tag(o);
                return null;
            }
        });
        return result;
    }

    private WriteHandler<Object, Object> convertRubyToJava(final ThreadContext context, final RubyObject handler) {
        return new WriteHandler<Object, Object>() {
            @Override
            public <V> WriteHandler<Object, V> getVerboseHandler() {
                return null;
            }

            @Override
            public Object rep(Object o) {
                IRubyObject ret =
                        handler.callMethod(context, "rep", JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), o));
                return ret.toJava(Object.class);
            }

            @Override
            public String stringRep(Object o) {
                RubyString ret =
                        (RubyString) handler.callMethod(context, "string_rep", JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), o));
                return ret.asJavaString();
            }

            @Override
            public String tag(Object o) {
                IRubyObject ret =
                        handler.callMethod(context, "tag", JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), o));
                if (ret.isNil()) {
                    return null;
                } else {
                    return ((RubyString)ret).asJavaString();
                }
            }
        };
    }

    protected IRubyObject write(ThreadContext context, IRubyObject arg) {
        try {
            writer.write(arg);
        } catch (Throwable t) {
            // TODO: use log api to spit out java exception
            //e.printStackTrace();
            if (t.getCause() != null) {
                throw context.getRuntime().newRuntimeError(t.getCause().getMessage());
            } else {
                throw context.getRuntime().newRuntimeError(t.getMessage());
            }
        }
        return context.getRuntime().getNil();
    }
}
