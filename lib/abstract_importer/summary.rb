module AbstractImporter
  class Summary < Struct.new(:total, :redundant, :created, :already_imported, :invalid, :ms, :skipped)
    
    def initialize
      super(0,0,0,0,0,0,0)
    end
    
  end
end
