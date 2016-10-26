module AbstractImporter
  module Reporters
    class NullReporter < BaseReporter

      def start_all(importer)
      end

      def finish_all(importer, ms)
      end

      def finish_setup(importer, ms)
      end

      def start_collection(collection)
      end

    end
  end
end
