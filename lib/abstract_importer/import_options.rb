module AbstractImporter
  class ImportOptions
    CALLBACKS = [ :finder,
                  :rescue,
                  :before_build,
                  :before_batch,
                  :before_create,
                  :before_update,
                  :before_save,
                  :after_create,
                  :after_update,
                  :after_save,
                  :before_all,
                  :after_all ]

    CALLBACKS.each do |callback|
      attr_reader :"#{callback}_callback"

      class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{callback}(sym=nil, &block)
        @#{callback}_callback = sym || block
      end
      RUBY
    end

  end
end
