require "abstract_importer/strategies/base"

module AbstractImporter
  module Strategies
    class DefaultStrategy < Base


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

        if create_record(hash)
          summary.created += 1
        else
          summary.invalid += 1
        end
      rescue ::AbstractImporter::Skip
        summary.skipped += 1
        reporter.record_skipped hash
      end


      def create_record(hash)
        record = build_record(hash)

        return true if dry_run?

        invoke_callback(:before_create, record)
        invoke_callback(:before_save, record)

        # rescue_callback has one shot to fix things
        invoke_callback(:rescue, record) unless record.valid?

        if record.valid? && record.save
          invoke_callback(:after_create, hash, record)
          invoke_callback(:after_save, hash, record)
          id_map << record if remap_ids?

          reporter.record_created(record)
          clean_record(record)
          true
        else

          reporter.record_failed(record, hash)
          clean_record(record)
          false
        end
      end

      def build_record(hash)
        collection.model.new prepare_attributes(hash)
      end

      def clean_record(record)
        # If this record isn't able to be garbage-collected,
        # then we will print out all of the objects that are
        # retaining a reference to this one. Ruby's garbage-
        # collector is smart enough to clean up objects with
        # circular references; but if we free these now, we
        # will have fewer results to consider later.
        record.remove_instance_variable :@association_cache
        record.remove_instance_variable :@errors
      end

    end
  end
end
