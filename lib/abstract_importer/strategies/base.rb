module AbstractImporter
  module Strategies
    class Base
      attr_reader :collection

      delegate :summary,
               :remap_foreign_keys!,
               :redundant_record?,
               :invoke_callback,
               :use_id_map_for?,
               :dry_run?,
               :id_map,
               :scope,
               :reporter,
               :association_attrs,
               :generate_id,
               to: :collection

      def initialize(collection, options={})
        @collection = collection
        @remap_ids = options.fetch(:id_map, use_id_map_for?(collection))
      end

      def remap_ids?
        @remap_ids
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

        if remap_ids?
          hash = hash.merge(legacy_id: hash.delete(:id))
          if generate_id
            hash[:id] = generate_id.arity.zero? ? generate_id.call : generate_id.call(hash)
          end
        end

        hash.merge(association_attrs)
      end

    end
  end
end
