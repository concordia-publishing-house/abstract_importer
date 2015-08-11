module AbstractImporter
  class ImportOptions
    CALLBACKS = [ :finder,
                  :rescue,
                  :before_build,
                  :before_create,
                  :after_create,
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
