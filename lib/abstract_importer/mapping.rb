module AbstractImporter
  class Mapping
    attr_reader :collection, :foreign_key, :depends_on

    def initialize(collection, association)
      @collection = collection
      @depends_on = association.table_name.to_sym
      @foreign_key = association.foreign_key.to_sym
    end

    def applicable?(attrs)
      attrs.key?(foreign_key)
    end

    def apply!(attrs)
      attrs[foreign_key] = apply(attrs)
    end

    def apply(attrs)
      collection.map_foreign_key(attrs[foreign_key], foreign_key, depends_on)
    end

    def inspect
      "#<#{self.class.name} #{self}>"
    end

    def to_s
      "#{collection.name}.#{foreign_key}"
    end

  end
end
