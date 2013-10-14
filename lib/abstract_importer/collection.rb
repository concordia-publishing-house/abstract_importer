module AbstractImporter
  class Collection < Struct.new(:name, :model, :table_name, :scope, :options)
  end
end
