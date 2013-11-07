module AbstractImporter
  class ImportOptions
    attr_reader :finder_callback,
                :rescue_callback,
                :before_build_callback,
                :before_create_callback,
                :after_create_callback,
                :before_all_callback,
                :after_all_callback
                
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
    
    def before_all(sym=nil, &block)
      @before_all_callback = sym || block
    end
    
    def after_all(sym=nil, &block)
      @after_all_callback = sym || block
    end
    
  end
end
