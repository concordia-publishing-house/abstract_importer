module AbstractImporter
  class IdMap
    
    class IdNotMappedError < StandardError; end
    
    def initialize
      @id_map = Hash.new { |hash, key| hash[key] = {} }
    end
    
    
    
    def init(table_name, map)
      table_name = table_name.to_sym
      @id_map[table_name] = map
    end
    
    def get(table_name)
      @id_map[table_name.to_sym].dup
    end
    alias :[] :get
    
    def <<(record)
      register(record: record)
    end
    
    def register(options={})
      if options.key?(:record)
        record = options[:record]
        table_name, record_id, legacy_id = record.class.table_name, record.id, record.legacy_id
      end
      table_name = options[:table_name] if options.key?(:table_name)
      legacy_id = options[:legacy_id] if options.key?(:legacy_id)
      record_id = options[:record_id] if options.key?(:record_id)
      
      table_name = table_name.to_sym
      @id_map[table_name][legacy_id] = record_id
    end
    
    def apply!(legacy_id, depends_on)
      return nil if legacy_id.blank?
      id_map = @id_map[depends_on]
      raise IdNotMappedError.new unless id_map.key?(legacy_id)
      id_map[legacy_id]
    end
    
  end
end
