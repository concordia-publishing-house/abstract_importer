module AbstractImporter
  class Summary < Struct.new(:total, :redundant, :created, :already_imported, :invalid, :ms, :skipped)
    
    def initialize
      super(0,0,0,0,0,0,0)
    end
    
    def average_ms
      return nil if total == 0
      ms / total
    end
    
  end
end
