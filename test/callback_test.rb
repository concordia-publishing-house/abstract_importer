require "test_helper"


class CallbackTest < ActiveSupport::TestCase



  context "before_build" do
    setup do
      plan do |import|
        import.students do |options|
          options.before_build { |attrs| attrs.merge(name: attrs[:name][/(\S+)/, 1]) }
        end
      end
    end

    should "should be invoked on the incoming attributes" do
      import!
      assert_equal ["Harry", "Ron", "Hermione"], account.students.pluck(:name)
    end

    should "allow you to skip certain records" do
      plan do |import|
        import.students do |options|
          options.before_build do |attrs|
            raise AbstractImporter::Skip if attrs[:name] == "Harry Potter"
          end
        end
      end

      import!
      assert_equal ["Ron Weasley", "Hermione Granger"], account.students.pluck(:name)
      assert_equal 1, results[:students].skipped
    end
  end



  context "before_create" do
    setup do
      plan do |import|
        import.students do |options|
          options.before_create { |student| student.house = "Gryffindor" }
        end
      end
    end

    should "should be invoked on imported records before they are saved" do
      import!
      assert_equal ["Gryffindor"], account.students.pluck(:house).uniq
    end
  end



  context "after_create" do
    setup do
      plan do |import|
        import.students do |options|
          options.after_create :callback
        end
      end
    end

    should "should be invoked after the record is created" do
      mock(importer).callback(hash_including(name: "Harry Potter"), satisfy(&:persisted?)).once
      mock(importer).callback(hash_including(name: "Ron Weasley"), satisfy(&:persisted?)).once
      mock(importer).callback(hash_including(name: "Hermione Granger"), satisfy(&:persisted?)).once
      import!
    end
  end



  context "rescue" do
    setup do
      plan do |import|
        import.locations do |options|
          options.rescue { |location| location.slug = location.slug.gsub(/[^a-z0-9\-]/, "") }
        end
      end
    end

    should "should be given a chance to amend an invalid record" do
      import!
      assert_equal ["godrics-hollow", "azkaban"], account.locations.pluck(:slug)
    end
  end



  context "before_all" do
    setup do
      plan do |import|
        import.students do |options|
          options.before_all :callback
        end
      end
    end

    should "should be invoked before the collection has been imported" do
      mock(importer).callback.once
      import!
    end
  end



  context "after_all" do
    setup do
      plan do |import|
        import.students do |options|
          options.after_all :callback
        end
      end
    end

    should "should be invoked after the collection has been imported" do
      mock(importer).callback.once
      import!
    end
  end



end
