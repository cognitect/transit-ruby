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
import org.jruby.RubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.ReadHandler;
import com.cognitect.transit.Reader;

public abstract class Base extends RubyObject {
    private static final long serialVersionUID = -2693178195157618851L;
    protected Reader reader;

    public Base(final Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
    }

    protected InputStream convertRubyIOToInputStream(ThreadContext context, IRubyObject rubyObject) {
        if (rubyObject.respondsTo("to_inputstream")) {
            return (InputStream) rubyObject.callMethod(context, "to_inputstream").toJava(InputStream.class);
        } else {
            throw rubyObject.getRuntime().newArgumentError("The first argument is not IO");
        }
    }

    protected Map<String, ReadHandler> convertRubyHandlersToJavaHandlers(
            final ThreadContext context, IRubyObject rubyObject) {
        if (!(rubyObject instanceof RubyHash)) {
            throw context.getRuntime().newArgumentError("The second argument is not Hash");
        }
        RubyHash opts = (RubyHash)rubyObject;
        IRubyObject h = opts.callMethod(context, "[]", context.getRuntime().newSymbol("handlers"));
        if (h instanceof RubyHash) {
            RubyHash handlers = (RubyHash)h;
            Map<String, ReadHandler> javaHandlers = new HashMap<String, ReadHandler>();
            for (Object key : handlers.keySet()) {
                final RubyObject handler = (RubyObject)handlers.get(key);
                javaHandlers.put(
                        key.toString(),
                        new ReadHandler() {
                           public IRubyObject fromRep(Object o) {
                               return handler.callMethod("from_rep", JavaUtil.convertJavaToRuby(context.getRuntime(), o));
                           }
                        });
            }
            return javaHandlers;
        }
        return null;
    }

    /**
       read method accepts a block
     **/
    protected IRubyObject read(ThreadContext context, Block block) {
        try {
            Object javaValue = reader.read();
            IRubyObject rubyValue;
            if (javaValue instanceof ArrayList) {
                rubyValue = convertArrayListToRubyArray(context, (ArrayList<?>)javaValue);
            } else {
                rubyValue = JavaUtil.convertJavaToUsableRubyObject(context.getRuntime(), javaValue);
            }
            if (rubyValue != null) {
                if (block.isGiven()) {
                    return block.yield(context, rubyValue);
                } else {
                    return rubyValue;
                }
            }
        } catch (RuntimeException e) {
            context.getRuntime().newRuntimeError(e.getMessage());
        }
        return context.getRuntime().getNil();
    }

    private IRubyObject convertArrayListToRubyArray(ThreadContext context, ArrayList<?> javaArray) {
        RubyArray rubyArray = context.getRuntime().newArray(javaArray.size());
        rubyArray.addAll(javaArray);
        return rubyArray;
    }
}
