require 'spec_helper'

module Transit
  describe Handler do
    describe 'registration' do
      let(:cache) { RollingCache.new }
      let(:io)    { StringIO.new }

      describe 'overrides' do
        it 'supports override of default string decoders' do
          uri_handler = Class.new do
            def tag()    "r"             end
            def rep(r)   "ENCODED: #{r}" end
            def string_rep(r) rep(r)     end
            def build(u) "DECODED: #{u}" end
          end

          handlers = Handler.new
          handlers.register(URI, uri_handler)
          decoder = Decoder.new(handlers)
          assert { decoder.decode("~rhttp://foo.com", cache) == "DECODED: http://foo.com" }

          writer = Writer.new(io, :json, handlers)
          writer.write({URI("sub.proto://domain.ext") => URI("proto://domain.ext")})
          assert { io.string == "{\"~rENCODED: sub.proto://domain.ext\":\"~rENCODED: proto://domain.ext\"}" }
        end

        it 'supports override of default hash decoders' do
          set_handler = Class.new do
            def tag()         "set"    end
            def rep(s)        Handler::TaggedMap.new(:array, ["ENCODED"] + s.to_a, nil) end
            def string_rep(s) rep(s) end
            def build(s)      "DECODED: #{s.map {|e| e}}" end
          end

          set = Set.new([1,2,3])

          handlers = Handler.new
          handlers.register(Set, set_handler)
          decoder = Decoder.new(handlers)
          assert { decoder.decode({"~#set" => set}, cache) == "DECODED: [1, 2, 3]"}

          writer = Writer.new(io, :json, handlers)
          writer.write(Set.new([1,2,3]))
          assert { io.string == "{\"~#set\":[\"ENCODED\",1,2,3]}" }
        end
      end

      describe 'extensions' do
        it 'supports string-based extensions' do
          date_handler = Class.new do
            def tag; "D"; end
            def rep(d) d.to_s end
            def string_rep(d) rep(d) end
            def build(d); Date.parse(d); end
          end

          handlers = Handler.new
          handlers.register(Date, date_handler)
          decoder = Decoder.new(handlers)
          assert { decoder.decode("~D2014-03-15", cache) == Date.new(2014,3,15) }

          writer = Writer.new(io, :json, handlers)
          writer.write({Date.new(2014,1,2) => Date.new(2014,1,3)})
          assert { io.string == "{\"~D2014-01-02\":\"~D2014-01-03\"}" }
        end

        it 'supports hash based extensions' do
          person_class = Struct.new("Person", :first_name, :last_name)
          person_handler = Class.new do
            def tag; "Xperson" end
            def rep(p) Handler::TaggedMap.new(:map, {:first_name => p.first_name, :last_name => p.last_name}, nil) end
            def string_rep(p) rep(p).to_s  end
            define_method(:build) {|p| person_class.new(p[:first_name],p[:last_name])}
          end

          handlers = Handler.new
          handlers.register(person_class, person_handler)
          decoder = Decoder.new(handlers)
          person = person_class.new("J", "D")
          assert { decoder.decode({"~#Xperson"=>{"~:first_name" => "J","~:last_name" => "D"}}, cache) == person }

          writer = Writer.new(io, :json, handlers)
          writer.write([person])
          assert { io.string == "[{\"~#Xperson\":{\"~:first_name\":\"J\",\"~:last_name\":\"D\"}}]" }
        end

        it 'supports hash based extensions that decode to nil'  do
          my_nil_handler = Class.new do
            def tag; "Xmynil"; end
            def build(n) nil; end
          end
          handlers = Handler.new
          handlers.register(NilClass, my_nil_handler)
          decoder = Decoder.new(handlers)
          assert { decoder.decode({"~#Xmynil" => :anything }, cache) == nil }
        end

        it 'supports hash based extensions that decode to false' do
          false_handler = Class.new do
            def tag; "Xmyfalse"; end
            def build(n) false; end
          end
          handlers = Handler.new
          handlers.register(FalseClass, false_handler)
          decoder = Decoder.new(handlers)
          assert { decoder.decode({"~#Xmyfalse" => :anything }, cache) == false }
        end
      end
    end
  end
end
