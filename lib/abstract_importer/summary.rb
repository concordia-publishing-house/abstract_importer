module AbstractImporter
  class Summary < Struct.new(:total, :existing_records, :new_records, :already_imported, :invalid, :ms)
    
    def initialize
      super(0,0,0,0,0,0)
    end
    
  end
end
