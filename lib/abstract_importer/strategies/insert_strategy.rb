require "abstract_importer/strategies/base"

module AbstractImporter
  module Strategies
    class InsertStrategy < Base

      def initialize(collection, options={})
        super
        @batch = []
        @batch_size = options.fetch(:batch_size, 250)
        @bulk_operation = options[:on_duplicate] == :update ? :upsert_all : :insert_all
        @insert_options = options.slice(:unique_by)
        @insert_options.merge!(returning: [:legacy_id, :id]) if remap_ids?
      end


      def process_record(hash)
        summary.total += 1

        if already_imported?(hash)
          summary.already_imported += 1
          reporter.record_skipped hash
          return
        end

        remap_foreign_keys!(hash)

        if redundant_record?(hash)
          summary.redundant += 1
          reporter.record_skipped hash
          return
        end

        add_to_batch prepare_attributes(hash)

      rescue ::AbstractImporter::Skip
        summary.skipped += 1
        reporter.record_skipped hash
      end


      def flush
        invoke_callback(:before_batch, @batch)

        insert_batch(@batch)

        summary.created += @batch.length
        reporter.batch_inserted(@batch.length)

        @batch = []
      end


      def insert_batch(batch)
        return if batch.empty?

        result = collection.scope.public_send(@bulk_operation, batch, @insert_options)
        add_batch_to_id_map(result) if remap_ids?
      end


      def add_to_batch(attributes)
        @batch << attributes
        legacy_id, id = attributes.values_at(:legacy_id, :id)
        id_map.merge! collection.table_name, legacy_id => id if id && legacy_id
        flush if @batch.length >= @batch_size
      end


      def add_batch_to_id_map(result)
        map = result.each_with_object({}) do |attrs, map|
          map[attrs.fetch("legacy_id")] = attrs.fetch("id")
        end
        id_map.merge! collection.table_name, map
      end


    end
  end
end
