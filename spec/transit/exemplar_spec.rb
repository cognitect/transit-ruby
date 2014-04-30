require 'spec_helper'
require 'pry'

# Assumes that the examples are in the simple_examples dir at the top.

TOP_DIR=File.dirname(File.dirname(File.dirname(__FILE__)))

ARRAY_SIMPLE = [1, 2, 3]
ARRAY_MIXED = [0, 1, 2.0, true, false, 'five', :six, Transit::TransitSymbol.new(:seven), '~eight', nil]
ARRAY_NESTED = [ARRAY_SIMPLE, ARRAY_MIXED]
SMALL_STRINGS = ["","a","ab","abc","abcd","abcde","abcdef"]
POWERS_OF_TWO = (0..65).map {|x| 2**x}
INTERESTING_INTS = (POWERS_OF_TWO.map {|x| ints_centered_on(x, 2)}).flatten

UUIDS = [
  Transit::UUID.new('5a2cbea3-e8c6-428b-b525-21239370dd55'),
  Transit::UUID.new('d1dc64fa-da79-444b-9fa4-d4412f427289'),
  Transit::UUID.new('501a978e-3a3e-4060-b3be-1cf2bd4b1a38'),
  Transit::UUID.new('b3ba141a-a776-48e4-9fae-a28ea8571f58')]

URIS = [
  Addressable::URI.parse('http://example.com'),
  Addressable::URI.parse('ftp://example.com'),
  Addressable::URI.parse('file:///path/to/file.txt'),
  Addressable::URI.parse('http://www.詹姆斯.com/')]

DATES = [-6106017600000, 0, 946728000000, 1396909037000].map {|x| Transit::DateTimeUtil.from_millis(x)}

SYMBOLS = [:a, :ab ,:abc ,:abcd, :abcde, :a1, :b2, :c3, :a_b]
TRANSIT_SYMBOLS = SYMBOLS.map {|x| Transit::TransitSymbol.new(x)}

SET_SIMPLE = Set.new(ARRAY_SIMPLE)
SET_MIXED = Set.new(ARRAY_MIXED)
SET_NESTED= Set.new([SET_SIMPLE, SET_MIXED])

MAP_SIMPLE = {a: 1, b: 2, c: 3}
MAP_MIXED = {:a=>1, :b=>"a string", :c=>true}
MAP_NESTED = {simple: MAP_SIMPLE, mixed: MAP_MIXED}

Exemplar = Struct.new(:name, :expected_value)

EXEMPLARS = [
  Exemplar.new('nil', nil),
  Exemplar.new('true',  true),
  Exemplar.new('false', false),
  Exemplar.new('zero',  0),
  Exemplar.new('one', 1),
  Exemplar.new('one_string', 'hello'),
  Exemplar.new('one_keyword', :hello),
  Exemplar.new('one_symbol',  Transit::TransitSymbol.new('hello')),
  Exemplar.new('one_date', Transit::DateTimeUtil.from_millis(946728000000)),
  Exemplar.new("vector_simple", ARRAY_SIMPLE),
  Exemplar.new("vector_empty", []),
  Exemplar.new("vector_mixed", ARRAY_MIXED),
  Exemplar.new("vector_nested", ARRAY_NESTED),
  Exemplar.new("small_strings", SMALL_STRINGS ),
  Exemplar.new("strings_tilde", SMALL_STRINGS.map{|s| "~#{s}"}),
  Exemplar.new("strings_hash", SMALL_STRINGS.map{|s| "##{s}"}),
  Exemplar.new("strings_hat", SMALL_STRINGS.map{|s| "^#{s}"}),
  Exemplar.new("small_ints", ints_centered_on(0)),
  Exemplar.new("ints", (0...128).to_a),
  Exemplar.new("ints_interesting", INTERESTING_INTS),
  Exemplar.new("ints_interesting_neg", INTERESTING_INTS.map {|x| -1 * x}),
  Exemplar.new("doubles_small", ints_centered_on(0).map {|x| Float(x)}),
  Exemplar.new("doubles_interesting", [-3.14159, 3.14159, 4E11, 2.998E8, 6.626E-34]),
  Exemplar.new('one_uuid', UUIDS.first),
  Exemplar.new('uuids', UUIDS),
  Exemplar.new('one_uri', URIS.first),
  Exemplar.new('uris', URIS),
  Exemplar.new('dates_interesting', DATES),
  Exemplar.new('symbols', TRANSIT_SYMBOLS),
  Exemplar.new('keywords', SYMBOLS),
  Exemplar.new('list_simple', ARRAY_SIMPLE),
  Exemplar.new('list_empty', []),
  Exemplar.new('list_mixed', ARRAY_MIXED),
  Exemplar.new('list_nested', [ARRAY_SIMPLE, ARRAY_MIXED]),
  Exemplar.new('set_simple', SET_SIMPLE),
  Exemplar.new("set_empty", Set.new),
  Exemplar.new("set_mixed", SET_MIXED),
  Exemplar.new("set_nested", SET_NESTED),
  Exemplar.new('map_simple', MAP_SIMPLE),
  Exemplar.new('map_mixed',  MAP_MIXED),
  Exemplar.new('map_nested',  MAP_NESTED),
  Exemplar.new('map_string_keys',  {"first"=>1, "second"=>2, "third"=>3}),
  Exemplar.new('map_numeric_keys',  {1=>"one", 2=>"two"}),
  Exemplar.new('map_vector_keys', {[1,1] => 'one', [2, 2] => 'two'}),
  Exemplar.new('map_10_items', hash_of_size(10)),
  Exemplar.new("maps_two_char_sym_keys", [{:aa=>1, :bb=>2}, {:aa=>3, :bb=>4}, {:aa=>5, :bb=>6}]),
  Exemplar.new("maps_three_char_sym_keys", [{:aaa=>1, :bbb=>2}, {:aaa=>3, :bbb=>4}, {:aaa=>5, :bbb=>6}]),
  Exemplar.new("maps_four_char_sym_keys", [{:aaaa=>1, :bbbb=>2}, {:aaaa=>3, :bbbb=>4}, {:aaaa=>5, :bbbb=>6}]),
  Exemplar.new("maps_two_char_string_keys", [{'aa'=>1, 'bb'=>2}, {'aa'=>3, 'bb'=>4}, {'aa'=>5, 'bb'=>6}]),
  Exemplar.new("maps_three_char_string_keys", [{'aaa'=>1, 'bbb'=>2}, {'aaa'=>3, 'bbb'=>4}, {'aaa'=>5, 'bbb'=>6}]),
  Exemplar.new("maps_four_char_string_keys", [{'aaaa'=>1, 'bbbb'=>2}, {'aaaa'=>3, 'bbbb'=>4}, {'aaaa'=>5, 'bbbb'=>6}]),
  Exemplar.new("maps_unrecognized_keys", 
               [Transit::TaggedValue.new("~#abcde", :anything), Transit::TaggedValue.new("~#fghij", :"anything-else")]),
  Exemplar.new("map_unrecognized_vals", {key: "`~notrecognized"}),
  Exemplar.new("vector_unrecognized_vals", ["`~notrecognized"]),
  Exemplar.new("vector_93_keywords_repeated_twice", array_of_symbols(93, 186)),
  Exemplar.new("vector_94_keywords_repeated_twice", array_of_symbols(94, 188)),
  Exemplar.new("vector_95_keywords_repeated_twice", array_of_symbols(95, 190))
  ]

[10, 90, 91, 92, 93, 94, 95].each do |i|
    EXEMPLARS << Exemplar.new( "map_#{i}_nested", {f: hash_of_size(i), s: hash_of_size(i)})
end

def verify_exemplar(exemplar, type, suffix)
  path = "#{TOP_DIR}/simple-examples/#{exemplar.name}.#{suffix}"

  it "reads what we expect from #{path}" do
    raise "Can't open #{path}" unless File.exist?(path)
    File.open(path) do |io|
      actual_value = Transit::Reader.new(type).read(io)
      binding.pry unless actual_value == exemplar.expected_value
      assert { exemplar.expected_value == actual_value }
    end
  end
end


module Transit
  shared_examples "exemplars" do |type, suffix|
    EXEMPLARS.each {|ex| verify_exemplar(ex, type, suffix)}
  end

  describe "Json exemplars" do
    include_examples "exemplars", :json, 'json'
  end

  describe "MessagePack exemplars" do
    include_examples "exemplars", :msgpack, 'mp'
  end
end
