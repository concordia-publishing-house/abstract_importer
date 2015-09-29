module AbstractImporter
  class Collection < Struct.new(:name, :model, :table_name, :scope, :options)

    def association_attrs
      return @assocation_attrs if defined?(@assocation_attrs)

      # Instead of calling `tenant.people.build(__)`, we'll reflect on the
      # association to find its foreign key and its owner's id, so that we
      # can call `Person.new(__.merge(tenant_id: id))`.
      @assocation_attrs = {}
      assocation = scope.instance_variable_get(:@association)
      unless assocation.is_a?(ActiveRecord::Associations::HasManyThroughAssociation)
        @assocation_attrs.merge!(assocation.reflection.foreign_key.to_sym => assocation.owner.id)
      end
      @assocation_attrs.freeze
    end

  end
end
