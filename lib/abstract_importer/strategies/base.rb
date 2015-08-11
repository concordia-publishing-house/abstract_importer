module AbstractImporter
  module Strategies
    class Base
      attr_reader :collection

      delegate :summary,
               :remap_foreign_keys!,
               :redundant_record?,
               :invoke_callback,
               :dry_run?,
               :id_map,
               :scope,
               :reporter,
               to: :collection

      def initialize(collection)
        @collection = collection
      end

      def process_record(hash)
        raise NotImplementedError
      end

      def already_imported?(hash)
        id_map.contains? collection.table_name, hash[:id]
      end

    end
  end
end
