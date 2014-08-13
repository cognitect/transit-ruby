package com.cognitect.transit.ruby.handler;

import java.math.BigInteger;
import java.util.List;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBignum;
import org.jruby.RubyModule;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.ReadHandler;

public class RatioReadHandler implements ReadHandler<IRubyObject, List<BigInteger>> {
    private Ruby runtime;
    
    public RatioReadHandler(Ruby runtime) {
        this.runtime = runtime;
    }

    @Override
    public IRubyObject fromRep(List<BigInteger> rep) {
        RubyModule module = runtime.getClassFromPath("Transit::TaggedValue");
        IRubyObject tag = runtime.newString("ratio");
        RubyArray rubyRep = runtime.newArray(2);
        RubyBignum nominator = RubyBignum.newBignum(runtime, rep.get(0));
        RubyBignum denominator = RubyBignum.newBignum(runtime, rep.get(1));
        rubyRep.callMethod(runtime.getCurrentContext(), "<<", nominator);
        rubyRep.callMethod(runtime.getCurrentContext(), "<<", denominator);
        IRubyObject[] args = new IRubyObject[]{tag, rubyRep};
        return module.callMethod(runtime.getCurrentContext(), "new", args);
    }

}
