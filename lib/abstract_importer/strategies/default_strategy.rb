require "abstract_importer/strategies/base"

module AbstractImporter
  module Strategies
    class DefaultStrategy < Base


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

        if create_record(hash)
          summary.created += 1
        else
          summary.invalid += 1
        end
      rescue ::AbstractImporter::Skip
        summary.skipped += 1
      end


      def create_record(hash)
        hash = invoke_callback(:before_build, hash) || hash

        record = scope.build hash.merge(legacy_id: hash.delete(:id))

        return true if dry_run?

        invoke_callback(:before_create, record)
        invoke_callback(:before_save, record)

        # rescue_callback has one shot to fix things
        invoke_callback(:rescue, record) unless record.valid?

        if record.valid? && record.save
          invoke_callback(:after_create, hash, record)
          invoke_callback(:after_save, hash, record)
          id_map << record

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
