require "test_helper"


class ImporterTest < ActiveSupport::TestCase
  
  
  
  context "with a simple data source" do
    setup do
      plan do |import|
        import.students
      end
    end
    
    should "import the given records" do
      import!
      assert_equal ["Harry Potter", "Ron Weasley", "Hermione Granger"], account.students.pluck(:name)
    end
    
    should "record their legacy_id" do
      import!
      assert_equal [456, 457, 458], account.students.pluck(:legacy_id)
    end
    
    should "not import existing records twice" do
      account.students.create!(name: "Ron Weasley", legacy_id: 457)
      import!
      assert_equal 3, account.students.count
    end
  end
  
  
  
  context "with a complex data source" do
    setup do
      plan do |import|
        import.students
        import.parents
      end
    end
    
    should "preserve mappings" do
      import!
      harry = account.students.find_by_name("Harry Potter")
      assert_equal ["James Potter", "Lily Potter"], harry.parents.pluck(:name)
    end
    
    should "preserve mappings even when a record was previously imported" do
      harry = account.students.create!(name: "Harry Potter", legacy_id: 456)
      import!
      assert_equal ["James Potter", "Lily Potter"], harry.parents.pluck(:name)
    end
  end
  
  
  
  context "when a finder is specified" do
    setup do
      plan do |import|
        import.students do |options|
          options.finder { |attrs| parent.students.find_by_name(attrs[:name]) }
        end
        import.parents
      end
    end
    
    should "not import redundant records" do
      account.students.create!(name: "Ron Weasley", legacy_id: nil)
      import!
      assert_equal 3, account.students.count
    end
    
    should "preserve mappings" do
      harry = account.students.create!(name: "Harry Potter", legacy_id: nil)
      import!
      assert_equal ["James Potter", "Lily Potter"], harry.parents.pluck(:name)
    end
  end
  
  
  
  context "with a more complex data source" do
    setup do
      plan do |import|
        import.students
        import.subjects do |options|
          options.before_build do |attributes|
            attributes.merge(:student_ids => attributes[:student_ids].map do |student_id|
              map_foreign_key(student_id, :subjects, :student_id, :students)
            end)
          end
        end
        import.grades
      end
    end
    
    should "preserve mappings" do
      import!
      ron = account.students.find_by_name "Ron Weasley"
      assert_equal ["Advanced Potions: Acceptable", "History of Magic: Troll"], ron.report_card
    end
  end
  
  
  
end
