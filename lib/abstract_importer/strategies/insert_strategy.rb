require "abstract_importer/strategies/base"
require "activerecord/insert_many"

module AbstractImporter
  module Strategies
    class InsertStrategy < Base

      def initialize(collection, options={})
        super
        @batch = []
        @batch_size = options.fetch(:batch_size, 250)
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

        add_to_batch prepare_attributes(hash)

      rescue ::AbstractImporter::Skip
        summary.skipped += 1
      end


      def flush
        invoke_callback(:before_batch, @batch)

        insert_batch(@batch)

        id_map_record_batch(@batch) if remap_ids?

        summary.created += @batch.length
        reporter.batch_inserted(@batch.length)

        @batch = []
      end


      def insert_batch(batch)
        collection.scope.insert_many(batch)
      end


      def add_to_batch(attributes)
        @batch << attributes
        legacy_id, id = attributes.values_at(:legacy_id, :id)
        id_map.merge! collection.table_name, legacy_id => id if id && legacy_id
        flush if @batch.length >= @batch_size
      end


      def id_map_record_batch(batch)
        return if generate_id
        id_map.merge! collection.table_name,
          collection.scope.where(legacy_id: @batch.map { |hash| hash[:legacy_id] })
      end


    end
  end
end
