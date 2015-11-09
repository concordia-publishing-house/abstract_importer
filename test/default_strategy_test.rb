require "test_helper"


class DefaultStrategyTest < ActiveSupport::TestCase



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

    context "when {atomic: true}" do
      should "rollback the whole import if an part fails" do
        mock(importer).atomic? { true }
        mock.instance_of(Parent).save { raise "hell" }
        import! rescue
        assert_equal 0, account.parents.count, "No parents should have been imported with the exception"
        assert_equal 0, account.students.count, "Expected students to have been rolled back"
      end
    end

    context "when {atomic: false}" do
      should "not rollback the whole import if an part fails" do
        mock(importer).atomic? { false }
        mock.instance_of(Parent).save { raise "hell" }
        import! rescue
        assert_equal 0, account.parents.count, "No parents should have been imported with the exception"
        assert_equal 3, account.students.count, "Expected students not to have been rolled back"
      end
    end
  end



  context "with a dependency" do
    setup do
      depends_on :students
      plan do |import|
        import.parents
      end
    end

    should "preserve mappings when a dependency was imported by another importer" do
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



  context "with polymorphic associations" do
    setup do
      plan do |import|
        import.cats
        import.owls
        import.students
      end
    end

    should "preserve mappings" do
      import!
      assert_equal 2, account.students.map(&:pet).compact.count, "Expected two students to still be linked to their pets upon import"
      assert_kind_of Owl, account.students.find_by_name("Harry Potter").pet, "Expected Harry's pet to be an Owl"
      assert_kind_of Cat, account.students.find_by_name("Hermione Granger").pet, "Expected Harry's pet to be a Cat"
    end
  end



  context "When records already exist" do
    setup do
      plan do |import|
        import.students
      end
      account.students.create!(name: "Ron Weasley", legacy_id: 457)
    end

    should "not import existing records twice" do
      import!
      assert_equal 3, account.students.count
    end
  end



  context "When we specify collections to skip" do
    setup do
      plan do |import|
        import.students
        import.parents
      end
    end

    context "using :skip" do
      setup do
        options.merge!(skip: :parents)
      end

      should "not import the named collections" do
        import!
        assert_equal 3, account.students.length
        assert_equal 0, account.parents.length
      end
    end

    context "using :only" do
      setup do
        options.merge!(only: [:students])
      end

      should "import only the named collections" do
        import!
        assert_equal 3, account.students.length
        assert_equal 0, account.parents.length
      end
    end
  end



end
