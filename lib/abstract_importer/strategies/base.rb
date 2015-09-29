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
               :association_attrs,
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

      def flush
      end

      def prepare_attributes(hash)
        hash = invoke_callback(:before_build, hash) || hash

        legacy_id = hash.delete(:id)

        hash.merge(legacy_id: legacy_id).merge(association_attrs)
      end

    end
  end
end
