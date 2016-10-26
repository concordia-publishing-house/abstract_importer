require "test_helper"

class IdMapTest < ActiveSupport::TestCase

  context ".dup" do
    should "create an independent copy of an IdMap" do
      map1 = AbstractImporter::IdMap.new
      map1.merge! :examples, { "a" => 1 }

      map2 = map1.dup
      assert_equal({ "a" => 1 }, map2.get(:examples))

      map1.merge! :examples, { "b" => 2 }
      assert_equal({ "a" => 1 }, map2.get(:examples))
    end
  end

end
