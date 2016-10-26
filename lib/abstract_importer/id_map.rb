module AbstractImporter
  class IdMap

    class IdNotMappedError < StandardError; end

    def initialize
      @id_map = Hash.new { |hash, key| hash[key] = {} }
    end



    def init(table_name, query)
      table_name = table_name.to_sym
      @id_map[table_name] = {}
      merge! table_name, query
    end

    def merge!(table_name, query)
      table_name = table_name.to_sym
      @id_map[table_name].merge! Hash[query.pluck(:legacy_id, :id)]
    end

    def get(table_name)
      @id_map[table_name.to_sym].dup
    end
    alias :[] :get

    def contains?(table_name, id)
      @id_map[table_name.to_sym].key?(id)
    end

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

    def apply!(depends_on, legacy_id)
      return nil if legacy_id.blank?
      id_map = @id_map[depends_on]
      raise IdNotMappedError.new unless id_map.key?(legacy_id)
      id_map[legacy_id]
    end

  end
end
