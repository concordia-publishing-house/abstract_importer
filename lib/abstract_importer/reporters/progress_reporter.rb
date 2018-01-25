require "progressbar"

module AbstractImporter
  module Reporters
    class ProgressReporter < BaseReporter

      def finish_setup(importer, ms)
        total = importer.collections.reduce(0) do |total, collection|
          total + importer.count_collection(collection)
        end
        @pbar = ProgressBar.new("progress", total)
      end

      def finish_all(importer, ms)
        pbar.finish
        io.puts "Finished in #{distance_of_time(ms)}"
      end

      def start_collection(collection)
        # Say nothing
      end



      def record_created(record)
        pbar.inc
      end

      def record_failed(record, hash)
        pbar.inc
      end

      def record_skipped(hash)
        pbar.inc
      end

      def batch_inserted(size)
        pbar.inc size
      end

    protected
      attr_reader :pbar

    end
  end
end
