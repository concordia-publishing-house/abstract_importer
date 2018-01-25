require "abstract_importer/strategies/default_strategy"

module AbstractImporter
  module Strategies
    class ReplaceStrategy < DefaultStrategy


      def process_record(hash)
        summary.total += 1

        remap_foreign_keys!(hash)

        if redundant_record?(hash)
          summary.redundant += 1
          reporter.record_skipped hash
          return
        end

        if create_or_update_record(hash)
          summary.created += 1
        else
          summary.invalid += 1
        end
      rescue ::AbstractImporter::Skip
        summary.skipped += 1
        reporter.record_skipped hash
      end


      def create_or_update_record(hash)
        if already_imported?(hash)
          update_record(hash)
        else
          create_record(hash)
        end
      end


      def update_record(hash)
        hash = invoke_callback(:before_build, hash) || hash

        record = remap_ids? ? scope.find_by(legacy_id: hash.delete(:id)) : scope.find_by(id: hash[:id])
        record.attributes = hash

        return true if dry_run?

        invoke_callback(:before_update, record)
        invoke_callback(:before_save, record)

        # rescue_callback has one shot to fix things
        invoke_callback(:rescue, record) unless record.valid?

        if record.valid? && record.save
          invoke_callback(:after_update, hash, record)
          invoke_callback(:after_save, hash, record)

          reporter.record_created(record)
          true
        else

          reporter.record_failed(record, hash)
          false
        end
      end


    end
  end
end
