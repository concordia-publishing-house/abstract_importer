require "test_helper"


class ReplaceStrategyTest < ActiveSupport::TestCase

  setup do
    options.merge!(strategy: {students: :replace})
  end



  context "When records already exist" do
    setup do
      plan do |import|
        import.students
      end
      account.students.create!(name: "Ron Weasley", legacy_id: 457)
    end

    should "reimport the existing records" do
      import!
      assert_equal "Gryffindor", account.students.find_by_name("Ron Weasley").house,
        "Expected Ron's record to have been replaced with one that has a house"
    end
  end



end
