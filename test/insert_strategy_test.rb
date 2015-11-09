require "test_helper"


class ImporterTest < ActiveSupport::TestCase

  setup do
    options.merge!(strategy: {students: :insert})
  end



  context "with a simple data source" do
    setup do
      plan do |import|
        import.students
      end
    end

    should "import the records in batches" do
      mock.proxy(Student).insert_many(satisfy { |arg| arg.length == 3 })
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

  context "When the import would create a duplicate record" do
    setup do
      plan do |import|
        import.students do |options|
          options.rescue_batch do |batch|
            names = parent.students.pluck :name
            batch.reject! { |student| names.member? student[:name] }
          end
        end
      end
      account.students.create!(name: "Ron Weasley")
    end

    should "not import existing records twice" do
      import!
      assert_equal 3, account.students.count
    end
  end



end
