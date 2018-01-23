module AbstractImporter
  module Reporters
    class BaseReporter
      attr_reader :io

      def initialize(io)
        @io = io
      end



      def start_all(importer)
        io.puts "Importing #{importer.describe_source} to #{importer.describe_destination}\n"
      end

      def finish_all(importer, ms)
        io.puts "\n\nFinished in #{distance_of_time(ms)}"
      end

      def finish_setup(importer, ms)
      end

      def finish_teardown(importer, ms)
      end

      def start_collection(collection)
        io.puts "\n#{("="*80)}\nImporting #{collection.name}\n#{("="*80)}\n"
      end

      def finish_collection(collection, summary)
      end



      def record_created(record)
      end

      def record_failed(record, hash)
      end

      def record_skipped(hash)
      end

      def batch_inserted(size)
      end



      def count_notice(message)
      end

      def count_error(message)
      end



    protected

      def distance_of_time(milliseconds)
        milliseconds = milliseconds.to_i
        seconds = milliseconds / 1000
        milliseconds %= 1000
        minutes = seconds / 60
        seconds %= 60
        hours = minutes / 60
        minutes %= 60
        days = hours / 24
        hours %= 24

        time = []
        time << "#{days} days" unless days.zero?
        time << "#{hours} hours" unless hours.zero?
        time << "#{minutes} minutes" unless minutes.zero?
        time << "#{seconds}.#{milliseconds.to_s.rjust(3, "0")} seconds"
        time.join(", ")
      end

    end
  end
end
