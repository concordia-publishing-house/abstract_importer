require "abstract_importer/strategies/insert_strategy"
require "activerecord/insert_many"

module AbstractImporter
  module Strategies
    class UpsertStrategy < InsertStrategy


      # We won't skip any records for already being imported
      def already_imported?(hash)
        false
      end


      def insert_batch(batch)
        collection.scope.insert_many(batch, on_conflict: {
          column: remap_ids? ? :legacy_id : :id,
          do: :update
        })
      end


    end
  end
end
