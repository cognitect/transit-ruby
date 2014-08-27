package com.cognitect.transit.ruby.unmarshaler;

import java.io.InputStream;
import java.util.List;
import java.util.Map;

import org.msgpack.MessagePack;

import com.cognitect.transit.ArrayReader;
import com.cognitect.transit.DefaultReadHandler;
import com.cognitect.transit.MapReader;
import com.cognitect.transit.ReadHandler;
import com.cognitect.transit.Reader;
import com.cognitect.transit.SPI.ReaderSPI;
import com.cognitect.transit.impl.AbstractParser;
import com.cognitect.transit.impl.JsonParser;
import com.cognitect.transit.impl.ListBuilderImpl;
import com.cognitect.transit.impl.MapBuilderImpl;
import com.cognitect.transit.impl.MsgpackParser;
import com.cognitect.transit.impl.ReadCache;
import com.fasterxml.jackson.core.JsonFactory;

public class RubyReaders {
    private abstract static class ReaderImpl implements Reader, ReaderSPI {
        InputStream in;
        Map<String, ReadHandler<?,?>> handlers;
        DefaultReadHandler<?> defaultHandler;
        MapReader<?, Map<Object, Object>, Object, Object> mapBuilder;
        ArrayReader<?, List<Object>, Object> listBuilder;
        ReadCache cache;
        AbstractParser p;
        boolean initialized;

        public ReaderImpl(InputStream in, Map<String, ReadHandler<?,?>> handlers, DefaultReadHandler<?> defaultHandler) {
            this.initialized = false;
            this.in = in;
            this.handlers = handlers;
            this.defaultHandler = defaultHandler;
            this.cache = new ReadCache();
        }

        @Override
        @SuppressWarnings("unchecked")
        public <T> T read() {
            if (!initialized) initialize();
            try {
                return (T) p.parse(cache.init());
            } catch (Throwable e) {
                throw new RuntimeException(e);
            }
        }

        @Override
        public Reader setBuilders(MapReader<?, Map<Object, Object>, Object, Object> mapBuilder,
                                  ArrayReader<?, List<Object>, Object> listBuilder) {
            if (initialized) throw new IllegalStateException("Cannot set builders after read has been called");
            this.mapBuilder = mapBuilder;
            this.listBuilder = listBuilder;
            return this;
        }

        private void ensureBuilders() {
            if (mapBuilder == null) mapBuilder = new MapBuilderImpl();
            if (listBuilder == null) listBuilder = new ListBuilderImpl();
        }

        protected void initialize() {
            ensureBuilders();
            p = createParser();
            initialized = true;
        }

        protected abstract AbstractParser createParser();
    }

    static class JsonReaderImpl extends ReaderImpl {

        public JsonReaderImpl(InputStream in, Map<String, ReadHandler<?,?>> handlers, DefaultReadHandler<?> defaultHandler) {
            super(in, handlers, defaultHandler);
        }

        @Override
        protected AbstractParser createParser() {
            try {
                JsonFactory jf = new JsonFactory();
                com.fasterxml.jackson.core.JsonParser json_parser = jf.createParser(in);
                json_parser.enable(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_NON_NUMERIC_NUMBERS);
                return new JsonParser(json_parser, handlers, defaultHandler,
                        mapBuilder, listBuilder);
            } catch (Throwable e) {
                throw new RuntimeException(e);
            }
        }
    }

    static class MsgPackReaderImpl extends ReaderImpl {

        public MsgPackReaderImpl(InputStream in, Map<String, ReadHandler<?,?>> handlers, DefaultReadHandler<?> defaultHandler) {
            super(in, handlers, defaultHandler);
        }

        @Override
        protected AbstractParser createParser() {
            MessagePack mp = new MessagePack();
            return new MsgpackParser(mp.createUnpacker(in), handlers, defaultHandler,
                    mapBuilder, listBuilder);
        }
    }
}
