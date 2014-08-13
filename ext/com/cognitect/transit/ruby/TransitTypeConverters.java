package com.cognitect.transit.ruby;

import org.jruby.Ruby;
import org.jruby.RubyFixnum;
import org.jruby.RubySymbol;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;

import com.cognitect.transit.Keyword;
import com.cognitect.transit.TransitFactory;

public class TransitTypeConverters {

    public static JavaUtil.JavaConverter TRANSIT_LONG_CONVERTER = new TransitJavaConverter(Long.class) {
        @Override
        public IRubyObject convert(Ruby runtime, Object o) {
            return runtime.newFixnum((Long)o);
        }
    };

    public static JavaUtil.JavaConverter TRANSIT_DEFAULT_CONVERTER = new TransitJavaConverter(Object.class) {
        @Override
        public IRubyObject convert(Ruby runtime, Object o) {
            return JavaUtil.convertJavaToUsableRubyObject(runtime, o);
        }
    };

    public static JavaUtil.JavaConverter converter(Object o) {
        if (o instanceof Long) {
            return TRANSIT_LONG_CONVERTER;
        } else {
            return TRANSIT_DEFAULT_CONVERTER;
        }
    }

    abstract static class TransitJavaConverter extends JavaUtil.JavaConverter {
        public TransitJavaConverter(Class<?> type) {
            super(type);
        }

        @Override
        public void set(Ruby runtime, Object array, int i, IRubyObject value) {
            throw runtime.newNotImplementedError("will be implemented if necessary");        
        }

        @Override
        public IRubyObject get(Ruby runtime, Object array, int i) {
            throw runtime.newNotImplementedError("will be implemented if necessary");
        }
    }

    public static Object convertRubyToTransitType(IRubyObject value) {
        if (value instanceof RubySymbol) {
            return convertRubySymbolToKeyword((RubySymbol)value);
        } else if (value instanceof RubyFixnum) {
            return ((RubyFixnum)value).toJava(Long.class);
        }
        return value.toJava(Object.class);
    }

    public static Keyword convertRubySymbolToKeyword(RubySymbol rubySymbol) {
        return TransitFactory.keyword(rubySymbol.toString());
    }
}