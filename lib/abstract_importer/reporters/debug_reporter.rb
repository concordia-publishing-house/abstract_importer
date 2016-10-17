module AbstractImporter
  module Reporters
    class DebugReporter < BaseReporter
      attr_reader :invalid_params

      def initialize(io)
        super
        @notices = {}
        @errors  = {}
        @invalid_params = {}
      end



      def start_all(importer)
        super
      end

      def finish_all(importer, ms)
        print_invalid_params
        super
      end



      def finish_setup(importer, ms)
        super
      end



      def start_collection(collection)
        super
        @notices = {}
        @errors  = {}
      end

      def finish_collection(collection, summary)
        print_summary summary, collection.name
        print_messages @notices, "Notices"
        print_messages @errors,  "Errors"
      end



      def record_failed(record, hash)
        error_messages = invalid_params[record.class.name] ||= Hash.new { |hash, key| hash[key] = [] }
        record.errors.full_messages.each do |error_message|
          error_messages[error_message].push hash
          count_error(error_message)
        end
      end



      def status(s)
        io.puts s
      end

      def stat(s)
        io.puts "  #{s}"
      end
      alias :info :stat

      def file(s)
        io.puts s.inspect
      end



      def count_notice(message)
        @notices[message] = (@notices[message] || 0) + 1
      end

      def count_error(message)
        @errors[message] = (@errors[message] || 0) + 1
      end



    private

      def print_invalid_params
        return if invalid_params.empty?
        status "\n\n\n#{("="*80)}\nInvalid records\n#{("="*80)}"
        invalid_params.each do |model_name, errors|
          status "\n\n--#{model_name}#{("-"*(78 - model_name.length))}"
          errors.each do |error_message, hashes|
            status "\n  #{error_message}:"
            hashes.each do |hash|
              status "\n"
              hash.each do |key, value|
                status "    #{key.inspect}\t#{value.inspect}"
              end
            end
          end
        end
      end

      def print_summary(summary, plural)
        stat "\n  #{summary.total} #{plural} were found"
        if summary.total > 0
          stat "#{summary.already_imported} #{plural} were imported previously"
          stat "#{summary.redundant} #{plural} would create duplicates and will not be imported"
          stat "#{summary.invalid} #{plural} were invalid"
          stat "#{summary.skipped} #{plural} were skipped"
          stat "#{summary.created} #{plural} were imported"
          stat "#{distance_of_time(summary.ms)} elapsed (#{summary.average_ms.to_i}ms each)"
        else
          stat "#{distance_of_time(summary.ms)} elapsed"
        end
      end

      def print_messages(array, caption)
        return if array.empty?
        status "\n--#{caption}#{("-"*(78-caption.length))}\n\n"
        array.each do |message, count|
          stat "#{count} × #{message}"
        end
      end

    end
  end
end
