module AbstractImporter
  class ImportOptions
    attr_reader :finder_callback,
                :rescue_callback,
                :before_build_callback,
                :before_create_callback,
                :after_create_callback,
                :on_complete_callback
                
    def finder(sym=nil, &block)
      @finder_callback = sym || block
    end
    
    def before_build(sym=nil, &block)
      @before_build_callback = sym || block
    end
    
    def before_create(sym=nil, &block)
      @before_create_callback = sym || block
    end
    
    def after_create(sym=nil, &block)
      @after_create_callback = sym || block
    end
    
    def rescue(sym=nil, &block)
      @rescue_callback = sym || block
    end
    
    def on_complete(sym=nil, &block)
      @on_complete_callback = sym || block
    end
    
  end
end
