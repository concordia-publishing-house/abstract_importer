require "abstract_importer/strategies/insert_strategy"
require "activerecord/insert_many"

module AbstractImporter
  module Strategies
    class UpsertStrategy < InsertStrategy

      def initialize(collection, options={})
        super
        @insert_options.reverse_merge!(on_conflict: { column: remap_ids? ? (association_attrs.keys + [:legacy_id]) : :id, do: :update })
      end

      # We won't skip any records for already being imported
      def already_imported?(hash)
        false
      end

    end
  end
end
