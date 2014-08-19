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
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.WriteHandler;
import com.cognitect.transit.Writer;

public class Base extends RubyObject {
    private static final long serialVersionUID = -3179062656279837886L;
    protected Map<String, WriteHandler<?, ?>> handlers;
    protected Writer writer;

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

    protected void convertDefaultRubyHandlersToJavaHandler(
            final ThreadContext context) {
        handlers = new HashMap<String, WriteHandler<?,?>>();
        Object ivar = this.getInstanceVariable("@handlers");
        if (ivar instanceof RubyHash) {
            RubyHash h = (RubyHash)ivar;
            for (Object key : h.keySet()) {
                final RubyObject handler = (RubyObject) h.get(key);
                handlers.put(
                        key.toString(),
                        convertRubyToJava(context, handler));
            }
        }
    }
    
    protected void convertUserDefinedRubyHandlersToJavaHandler(
            final ThreadContext context, IRubyObject arg) {
        if (!(arg instanceof RubyHash)) {
            throw context.getRuntime().newArgumentError("The second argument is not Hash");
        }
        RubyHash opts = (RubyHash)arg;
        IRubyObject h = opts.callMethod(context, "[]", context.getRuntime().newSymbol("handlers"));
        if (h instanceof RubyHash) {
            RubyHash userDefinedHandlers = (RubyHash)h;
        }
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
                RubyString ret =
                        (RubyString) handler.callMethod(context, "tag", JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), o));
                return ret.asJavaString();
            }
        };
    }

    protected Map<Class, WriteHandler<?, ?>> getProxy() {
        return new Map<Class, WriteHandler<?, ?>>() {
            @Override
            public int size() {
                return handlers.size();
            }

            @Override
            public boolean isEmpty() {
                return handlers.isEmpty();
            }

            @Override
            public boolean containsKey(Object key) {
                if ((key instanceof RubyClass) && (handlers.size() > 0)) {
                    return true;
                } else {
                    return false;
                }
            }

            @Override
            public boolean containsValue(Object value) {
                return handlers.containsValue(value);
            }

            @Override
            public WriteHandler<?, ?> get(Object key) {
                if (key instanceof RubyClass) {
                    return handlers.get(((RubyClass)key).getName());
                }
                return null;
            }

            @Override
            public WriteHandler<?, ?> put(Class key, WriteHandler<?, ?> value) {
                return null;
            }

            @Override
            public WriteHandler<?, ?> remove(Object key) {
                if (key instanceof RubyClass) {
                    return handlers.remove(((RubyClass)key).getName());
                }
                return null;
            }

            @Override
            public void putAll(
                    Map<? extends Class, ? extends WriteHandler<?, ?>> m) {
                // do nothing
            }

            @Override
            public void clear() {
                handlers.clear();
            }

            @Override
            public Set<Class> keySet() {
                return null;
            }

            @Override
            public Collection<WriteHandler<?, ?>> values() {
                return null;
            }

            @Override
            public Set<java.util.Map.Entry<Class, WriteHandler<?, ?>>> entrySet() {
                return null;
            }
        };
    }

    protected IRubyObject write(ThreadContext context, IRubyObject arg) {
        return null;
    }

}
