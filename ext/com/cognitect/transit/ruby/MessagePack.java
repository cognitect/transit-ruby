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

package com.cognitect.transit.ruby;

import java.io.ByteArrayInputStream;
import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import com.cognitect.transit.Reader;
import com.cognitect.transit.TransitFactory;

@JRubyClass(name="Transit::Unmarshaler::MessagePack")
public class MessagePack extends RubyObject {
    private static final long serialVersionUID = 8837562079042631858L;
    private Reader reader;
    MessagePack(final Ruby runtime, RubyClass rubyClass) {
        super(runtime, rubyClass);
    }

    /**
       args[0] - io   : any Ruby IO
       args[1] - opts : Ruby Hash
     **/
    @JRubyMethod(name="new", meta=true, required=1, rest=true)
    public static IRubyObject rbNew(ThreadContext context, IRubyObject klazz, IRubyObject[] args) {
        RubyClass rubyClass = (RubyClass)context.getRuntime().getClassFromPath("Transit::Unmarshaler::MessagePack");
        MessagePack messagepack = (MessagePack)rubyClass.allocate();
        messagepack.init(args);
        return messagepack;
    }

    private void init(IRubyObject[] args) {
        // TODO: do something necessary for args
        reader = TransitFactory.reader(TransitFactory.Format.MSGPACK, new ByteArrayInputStream("DUMMY".getBytes()));
    }

    @JRubyMethod
    public IRubyObject read(ThreadContext context, Block block) {
        System.out.println("Not yet implemented");
        return context.getRuntime().getNil();
    }
}
