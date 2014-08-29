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
        RubyClass json_unmarshaler = unmarshaler.defineClassUnder("Json", runtime.getObject(), new ObjectAllocator() {
            private com.cognitect.transit.ruby.unmarshaler.Json json = null;
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                if (json == null) {
                    json = new com.cognitect.transit.ruby.unmarshaler.Json(runtime, rubyClass);
                }
                try {
                    com.cognitect.transit.ruby.unmarshaler.Json clone =
                            (com.cognitect.transit.ruby.unmarshaler.Json)json.clone();
                    clone.setMetaClass(rubyClass);
                    return clone;
                } catch (CloneNotSupportedException e) {
                    return new com.cognitect.transit.ruby.unmarshaler.Json(runtime, rubyClass);
                }
            }
        });
        json_unmarshaler.defineAnnotatedMethods(com.cognitect.transit.ruby.unmarshaler.Json.class);

        RubyClass messagepack_unmarshaler = unmarshaler.defineClassUnder("MessagePack", runtime.getObject(), new ObjectAllocator() {
            private com.cognitect.transit.ruby.unmarshaler.MessagePack msgpack = null;  
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                if (msgpack == null) {
                    msgpack = new com.cognitect.transit.ruby.unmarshaler.MessagePack(runtime, rubyClass);
                }
                try {
                    com.cognitect.transit.ruby.unmarshaler.MessagePack clone =
                            (com.cognitect.transit.ruby.unmarshaler.MessagePack)msgpack.clone();
                    clone.setMetaClass(rubyClass);
                    return clone;
                } catch (CloneNotSupportedException e) {
                    return new com.cognitect.transit.ruby.unmarshaler.MessagePack(runtime, rubyClass);
                }
            }
        });
        messagepack_unmarshaler.defineAnnotatedMethods(com.cognitect.transit.ruby.unmarshaler.MessagePack.class);

        RubyModule marshaler = transit.defineModuleUnder("Marshaler");
        RubyClass json_marshaler = marshaler.defineClassUnder("Json", runtime.getObject(), new ObjectAllocator() {
            private com.cognitect.transit.ruby.marshaler.Json json = null;
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                if (json == null) {
                    json = new com.cognitect.transit.ruby.marshaler.Json(runtime, rubyClass);
                }
                try {
                    com.cognitect.transit.ruby.marshaler.Json clone =
                            (com.cognitect.transit.ruby.marshaler.Json)json.clone();
                    clone.setMetaClass(rubyClass);
                    return clone;
                } catch (CloneNotSupportedException e) {
                    return new com.cognitect.transit.ruby.marshaler.Json(runtime, rubyClass);
                }
            }
        });
        json_marshaler.defineAnnotatedMethods(com.cognitect.transit.ruby.marshaler.Json.class);

        RubyClass verbosejson_marshaler = marshaler.defineClassUnder("VerboseJson", runtime.getObject(), new ObjectAllocator() {
            private com.cognitect.transit.ruby.marshaler.VerboseJson verboseJson = null;
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                if (verboseJson == null) {
                    verboseJson = new com.cognitect.transit.ruby.marshaler.VerboseJson(runtime, rubyClass);
                }
                try {
                    com.cognitect.transit.ruby.marshaler.VerboseJson clone =
                            (com.cognitect.transit.ruby.marshaler.VerboseJson)verboseJson.clone();
                    clone.setMetaClass(rubyClass);
                    return clone;
                } catch (CloneNotSupportedException e) {
                    return new com.cognitect.transit.ruby.marshaler.VerboseJson(runtime, rubyClass);
                }
            }
        });
        verbosejson_marshaler.defineAnnotatedMethods(com.cognitect.transit.ruby.marshaler.VerboseJson.class);

        RubyClass messagepack_marshaler = marshaler.defineClassUnder("MessagePack", runtime.getObject(), new ObjectAllocator() {
            private com.cognitect.transit.ruby.marshaler.MessagePack msgpack = null;
            public IRubyObject allocate(Ruby runtime, RubyClass rubyClass) {
                if (msgpack == null) {
                    msgpack = new com.cognitect.transit.ruby.marshaler.MessagePack(runtime, rubyClass);
                }
                try {
                    com.cognitect.transit.ruby.marshaler.MessagePack clone =
                            (com.cognitect.transit.ruby.marshaler.MessagePack)msgpack.clone();
                    clone.setMetaClass(rubyClass);
                    return clone;
                } catch (CloneNotSupportedException e) {
                    return new com.cognitect.transit.ruby.marshaler.MessagePack(runtime, rubyClass);
                }
            }
        });
        messagepack_marshaler.defineAnnotatedMethods(com.cognitect.transit.ruby.marshaler.MessagePack.class);

        return true;
    }
}
