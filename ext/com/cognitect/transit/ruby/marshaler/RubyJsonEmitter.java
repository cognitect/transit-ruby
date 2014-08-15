package com.cognitect.transit.ruby.marshaler;

import java.util.Map;

import com.cognitect.transit.WriteHandler;
import com.cognitect.transit.impl.JsonEmitter;
import com.fasterxml.jackson.core.JsonGenerator;

public class RubyJsonEmitter extends JsonEmitter {

    public RubyJsonEmitter(JsonGenerator gen,
            Map<Class, WriteHandler<?, ?>> handlers) {
        super(gen, handlers);
        // TODO Auto-generated constructor stub
    }
}
