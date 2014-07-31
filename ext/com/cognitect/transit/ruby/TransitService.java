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

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;

public class TransitService implements BasicLibraryService {

    @Override
    public boolean basicLoad(Ruby runtime) throws IOException {
        RubyModule transit = runtime.defineModule("Transit");
        RubyModule unmarshaler = transit.defineModuleUnder("Unmarshaler");
        RubyClass json = unmarshaler.defineClassUnder("Json", runtime.getObject(), new ObjectAllocator() {
                public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                    return new com.cognitect.transit.ruby.unmarshaler.Json(runtime, rubyClass);
                }
            });
        json.defineAnnotatedMethods(com.cognitect.transit.ruby.unmarshaler.Json.class);

        RubyClass messagepack = unmarshaler.defineClassUnder("MessagePack", runtime.getObject(), new ObjectAllocator() {
                public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                    return new com.cognitect.transit.ruby.unmarshaler.MessagePack(runtime, rubyClass);
                }
            });
        messagepack.defineAnnotatedMethods(com.cognitect.transit.ruby.unmarshaler.MessagePack.class);

        return true;
    }
}
