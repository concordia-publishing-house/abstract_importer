require "abstract_importer/strategies/insert_strategy"

module AbstractImporter
  module Strategies
    class UpsertStrategy < InsertStrategy

      def initialize(collection, options={})
        super
        @bulk_operation = :upsert_all
        @insert_options.reverse_merge!(unique_by: remap_ids? ? (association_attrs.keys + %i{legacy_id}) : :id)
      end

      # We won't skip any records for already being imported
      def already_imported?(hash)
        false
      end

    end
  end
end
