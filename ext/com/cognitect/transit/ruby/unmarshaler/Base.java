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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyNil;
import org.jruby.RubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.DefaultReadHandler;
import com.cognitect.transit.ReadHandler;
import com.cognitect.transit.Reader;
import com.cognitect.transit.ruby.RubyMapReader;
import com.cognitect.transit.ruby.TransitTypeConverters;
import com.cognitect.transit.ruby.handler.CmapReadHandler;
import com.cognitect.transit.ruby.handler.KeywordReadHandler;
import com.cognitect.transit.ruby.handler.RatioReadHandler;

public abstract class Base extends RubyObject {
    private static final long serialVersionUID = -2693178195157618851L;
    protected Reader reader;

    public Base(final Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
    }
    
    protected static IRubyObject newDecoder(ThreadContext context, IRubyObject opts) {
        try {
            RubyClass decoderClass = (RubyClass) context.getRuntime().getClassFromPath("Transit::Decoder");
            return decoderClass.callMethod(context, "new", opts);
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
    }

    protected InputStream convertRubyIOToInputStream(ThreadContext context, IRubyObject rubyObject) {
        if (rubyObject.respondsTo("to_inputstream")) {
            return (InputStream) rubyObject.callMethod(context, "to_inputstream").toJava(InputStream.class);
        } else {
            throw rubyObject.getRuntime().newArgumentError("The first argument is not IO");
        }
    }

    protected Map<String, ReadHandler<?, ?>> convertRubyHandlersToJavaHandlers(
            final ThreadContext context, IRubyObject rubyObject) {
        if (!(rubyObject instanceof RubyHash)) {
            throw context.getRuntime().newArgumentError("The second argument is not Hash");
        }
        Map<String, ReadHandler<?, ?>> javaHandlers = overrideJavaHandlers(context.getRuntime());
        RubyHash opts = (RubyHash)rubyObject;
        IRubyObject h = opts.callMethod(context, "[]", context.getRuntime().newSymbol("handlers"));
        if (h instanceof RubyHash) {
            RubyHash handlers = (RubyHash)h;
            for (Object key : handlers.keySet()) {
                final RubyObject handler = (RubyObject)handlers.get(key);
                javaHandlers.put(
                        key.toString(),
                        new ReadHandler<IRubyObject, Object>() {
                           public IRubyObject fromRep(Object o) {
                               return handler.callMethod("from_rep",
                                           JavaUtil.convertJavaToUsableRubyObjectWithConverter(context.getRuntime(), o, TransitTypeConverters.converter(o)));
                           }
                        });
            }
        }
        return javaHandlers;
    }

    private Map<String, ReadHandler<?, ?>> overrideJavaHandlers(Ruby runtime) {
        Map<String, ReadHandler<?, ?>> javaHandlers = new HashMap<String, ReadHandler<?, ?>>();
        javaHandlers.put("cmap", new CmapReadHandler(runtime));
        javaHandlers.put("ratio", new RatioReadHandler(runtime));
        javaHandlers.put(":", new KeywordReadHandler(runtime));
        return javaHandlers;
    }

    protected DefaultReadHandler<?> convertRubyDefaultHandlerToJavaDefaultHandler(
            final ThreadContext context, IRubyObject rubyObject) {
        if (!(rubyObject instanceof RubyHash)) {
            throw context.getRuntime().newArgumentError("The second argument is not Hash");
        }
        RubyHash opts = (RubyHash)rubyObject;
        IRubyObject c = opts.callMethod(context, "[]", context.getRuntime().newSymbol("default_handler"));
        if (c instanceof RubyNil) {
            return null;
        } else {
            final RubyObject default_handler = (RubyObject)c;
            DefaultReadHandler<IRubyObject> javaDefaultHandler =
                    new DefaultReadHandler<IRubyObject>() {
                        public IRubyObject fromRep(String tag, Object rep) {
                            return default_handler.callMethod("from_rep",
                                        context.getRuntime().newString(tag),
                                        JavaUtil.convertJavaToUsableRubyObjectWithConverter(context.getRuntime(), rep, TransitTypeConverters.converter(rep)));
                        }
            };
            return javaDefaultHandler;
        }
    }

    /**
       read method accepts a block
     **/
    protected IRubyObject read(ThreadContext context, Block block) {
        try {
            Object o = reader.read();
            IRubyObject value =
                    JavaUtil.convertJavaToUsableRubyObjectWithConverter(context.getRuntime(), o, TransitTypeConverters.converter(o));
            if (value != null) {
                if (block.isGiven()) {
                    return block.yield(context, value);
                } else {
                    return value;
                }
            }
        } catch (Throwable t) {
            throw context.getRuntime().newRuntimeError(t.getMessage());
        }
        return context.getRuntime().getNil();
    }
}
