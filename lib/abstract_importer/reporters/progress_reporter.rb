require "progressbar"

module AbstractImporter
  module Reporters
    class ProgressReporter < BaseReporter

      def finish_setup(importer, ms)
        super

        ms = Benchmark.ms do
          total = importer.collections.reduce(0) do |total, collection|
            total + importer.source.public_send(collection.name).count
          end
          @pbar = ProgressBar.new("progress", total)
        end
        io.puts "Counted records to import in #{distance_of_time(ms)}"
      end

      def finish_all(importer, ms)
        pbar.finish
        super
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

      def batch_inserted(size)
        pbar.inc size
      end

    private
      attr_reader :pbar

    end
  end
end
