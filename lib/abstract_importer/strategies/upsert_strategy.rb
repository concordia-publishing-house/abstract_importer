require "abstract_importer/strategies/insert_strategy"
require "activerecord/insert_many"

module AbstractImporter
  module Strategies
    class UpsertStrategy < InsertStrategy


      def process_record(hash)
        summary.total += 1

        remap_foreign_keys!(hash)

        if redundant_record?(hash)
          summary.redundant += 1
          return
        end

        @batch << prepare_attributes(hash)
        flush if @batch.length >= @batch_size

      rescue ::AbstractImporter::Skip
        summary.skipped += 1
      end


      def flush
        invoke_callback(:before_batch, @batch)

        collection.scope.insert_many(@batch, on_conflict: {
          column: remap_ids? ? :legacy_id : :id,
          do: :update
        })

        if remap_ids?
          id_map.merge! collection.table_name,
            collection.scope.where(legacy_id: @batch.map { |hash| hash[:legacy_id] })
        end

        summary.created += @batch.length
        reporter.batch_inserted(@batch.length)

        @batch = []
      end


    end
  end
end
