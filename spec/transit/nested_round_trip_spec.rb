require 'spec_helper'

module Transit
  MyPhoneNumber = Struct.new(:area, :number)
  MyAddress = Struct.new(:street, :number)
  MyPerson = Struct.new(:name, :address, :number)

  class MyPhoneNumberHandler
    def tag(_) "number" end
    def rep(p) { "area" => p.area, "number" => p.number } end
    def string_rep(_) nil end
  end

  class MyPhoneNumberReader
    def from_rep(v)
      MyPhoneNumber.new(v["area"], v["number"])
    end
  end

  class MyAddressHandler
    def tag(_) "address" end
    def rep(a) { "street" => a.street, "number" => a.number } end
    def string_rep(_) nil end
  end

  class MyAddressReader
    def from_rep(v)
      MyAddress.new(v["street"], v["number"])
    end
  end

  class MyPersonHandler
    def tag(_) "person" end
    def rep(p) { "name" => p.name, "address" => p.address, "number" => p.number } end
    def string_rep(_) nil end
  end

  class MyPersonReader
    def from_rep(v)
     MyPerson.new(v["name"], v["address"], v["number"])
    end
  end

 
  context "rolling cache entries" do
    let(:person){
      MyPerson.new( "Elmo",
                  MyAddress.new("Sesame str", 15),
                  MyPhoneNumber.new("555", "12345678")
                )
    }

    let(:read_handlers){
      {
        "number"  => MyPhoneNumberReader.new,
        "address" => MyAddressReader.new,
        "person"  => MyPersonReader.new
      }
    }

    let(:write_handlers){
      {
        MyPhoneNumber => MyPhoneNumberHandler.new,
        MyAddress => MyAddressHandler.new,
        MyPerson => MyPersonHandler.new
      }
    }

    let(:io){ StringIO.new }
    let(:writer){ Transit::Writer.new(:json, io, handlers: write_handlers) }

    it 'knows how to write and read again, correctly using the cache' do
      writer.write(person)
      encoded_person = io.string

      reader = Transit::Reader.new(:json, StringIO.new(encoded_person), handlers: read_handlers)
      restored_person = reader.read

      expect(restored_person).to eq person
    end
  end
end
