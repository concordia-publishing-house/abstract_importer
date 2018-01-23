module AbstractImporter
  module Reporters
    class DotReporter < DebugReporter


      def record_created(record)
        io.print "."
        super
      end

      def record_failed(record, hash)
        io.print "×"
        super
      end

      def record_skipped(hash)
        io.print "_"
        super
      end

      def batch_inserted(size)
        io.print "." * size
        super
      end


    end
  end
end
