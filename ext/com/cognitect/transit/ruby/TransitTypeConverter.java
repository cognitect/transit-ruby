package com.cognitect.transit.ruby;

import java.util.Arrays;
import java.util.List;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

public class TransitTypeConverter {
    private static final List<String> specialString = Arrays.asList("NaN", "Infinity", "-Infinity");

    public static boolean needsCostomConverter(Object o) {
        if ((o instanceof String) && specialString.contains((String)o)) {
            return true;
        } else {
            return false;
        }
    }

    public static IRubyObject convertStringToFloat(Ruby runtime, Object o) {
        String str = (String)o;
        if ("NaN".equals(str)) {
            return runtime.newFloat(Double.NaN);
        } else if ("Infinity".equals(str)) {
            return runtime.newFloat(Double.POSITIVE_INFINITY);
        } else if ("-Infinity".equals(str)) {
            return runtime.newFloat(Double.NEGATIVE_INFINITY);
        } else {
            return runtime.getNil();
        }
    }
}
