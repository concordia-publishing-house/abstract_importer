module AbstractImporter
  class Collection < Struct.new(:name, :model, :table_name, :scope, :options)

    def initialize(name, scope, options=nil)
      super name, scope.model, scope.table_name, scope, options
    end

    def association_attrs
      return @association_attrs if defined?(@association_attrs)

      # Instead of calling `tenant.people.build(__)`, we'll reflect on the
      # association to find its foreign key and its owner's id, so that we
      # can call `Person.new(__.merge(tenant_id: id))`.
      @association_attrs = {}
      association = scope.instance_variable_get(:@association)
      if association
        unless association.is_a?(ActiveRecord::Associations::HasManyThroughAssociation)
          @association_attrs.merge!(association.reflection.foreign_key.to_sym => association.owner.id)
        end
        if association.reflection.inverse_of && association.reflection.inverse_of.polymorphic?
          @association_attrs.merge!(association.reflection.inverse_of.foreign_type.to_sym => association.owner.class.name)
        end
      end
      @association_attrs.freeze
    end

    def has_legacy_id?
      @has_legacy_id ||= model.column_names.member?("legacy_id")
    end

  end
end
