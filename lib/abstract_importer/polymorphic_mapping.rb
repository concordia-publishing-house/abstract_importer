module AbstractImporter
  class PolymorphicMapping < AbstractImporter::Mapping
    attr_reader :collection, :foreign_key, :foreign_type

    def initialize(collection, association)
      @collection = collection
      @foreign_key = association.foreign_key.to_sym
      @foreign_type = association.foreign_key.gsub(/_id$/, "_type").to_sym
      @table_name_by_foreign_model = Hash.new do |map, foreign_model|
        map[foreign_model] = foreign_model && foreign_model.constantize.table_name.to_sym
      end
    end

    def applicable?(attrs)
      attrs.key?(foreign_key) && attrs.key?(foreign_type)
    end
    alias applies_to? applicable?

    def foreign_model_for(attrs)
      attrs[foreign_type]
    end

    def foreign_table_for(attrs)
      table_name_for(foreign_model_for(attrs))
    end

    def apply(attrs)
      depends_on = foreign_table_for(attrs)
      collection.map_foreign_key(attrs[foreign_key], foreign_key, depends_on) if depends_on
    end
    alias [] apply

  private

    def table_name_for(foreign_model)
      @table_name_by_foreign_model[foreign_model]
    end

  end
end
