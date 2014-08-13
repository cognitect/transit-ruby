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
