require "abstract_importer/strategies/base"
require "activerecord/insert_many"

module AbstractImporter
  module Strategies
    class InsertStrategy < Base

      def initialize(collection)
        super
        @batch = []
        @batch_size = 250
      end


      def process_record(hash)
        summary.total += 1

        if already_imported?(hash)
          summary.already_imported += 1
          return
        end

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

        begin
          tries = (tries || 0) + 1
          collection.scope.insert_many(@batch)
        rescue
          raise if tries > 1
          invoke_callback(:rescue_batch, @batch)
          retry
        end

        ids = collection.scope.where(legacy_id: @batch.map { |hash| hash[:legacy_id] })
        id_map.merge! collection.table_name, ids

        summary.created += ids.length
        reporter.batch_inserted(ids.length)

        @batch = []
      end


    end
  end
end
