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

package com.cognitect.transit.ruby.handler;

import org.jruby.Ruby;
import org.jruby.RubySymbol;

import com.cognitect.transit.ReadHandler;

public class KeywordReadHandler implements ReadHandler<RubySymbol, String> {
    private Ruby runtime;

    public KeywordReadHandler(Ruby runtime) {
        this.runtime = runtime;
    }

    @Override
    public RubySymbol fromRep(String rep) {
        return runtime.newSymbol(rep);
    }
}
