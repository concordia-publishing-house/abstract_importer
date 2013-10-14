module AbstractImporter
  class Reporter
    
    def initialize(io, production)
      @io = io
      @notices = {}
      @errors  = {}
      @production = production
      @invalid_params = {}
    end
    
    attr_reader :io, :invalid_params
    
    
    
    def production?
      @production
    end
    
    
    
    def start_all(importer)
      status "Importing #{importer.describe_source} to #{importer.describe_destination}\n"
    end
    
    def finish_all(importer, ms)
      print_invalid_params
      status "\n\nFinished in #{distance_of_time(ms)}"
    end
    
    
    
    def finish_setup(ms)
      status "Setup took #{distance_of_time(ms)}\n"
    end
    
    
    
    def start_collection(collection)
      status "\n#{("="*80)}\nImporting #{collection.name}\n#{("="*80)}\n"
      @notices = {}
      @errors  = {}
    end
    
    def finish_collection(collection, summary)
      ms = summary[5]
      elapsed = distance_of_time(ms)
      stat "\n  #{summary[0]} #{collection.name} were found"
      if summary[0] > 0
        stat     "#{summary[3]} #{collection.name} were imported previously"
        stat     "#{summary[1]} #{collection.name} would create duplicates and will not be imported"
        stat     "#{summary[4]} #{collection.name} were invalid"
        stat     "#{summary[2]} #{collection.name} were imported"
      end
      stat     "#{elapsed} elapsed" << (summary[0] > 0 ? " (#{(ms / summary[0]).to_i}ms each)" : "")
      
      print_messages(@notices, "Notices")
      print_messages(@errors,  "Errors")
    end
    
    
    
    def record_created(record)
      io.print "." unless production?
    end
    
    def record_failed(record)
      io.print "×" unless production?
      
      error_messages = invalid_params[record.class.name] ||= {}
      record.errors.full_messages.each do |error_message|
        error_messages[error_message] = hash unless error_messages.key?(error_message)
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
      return if production?
      @notices[message] = (@notices[message] || 0) + 1
    end
    
    def count_error(message)
      @errors[message] = (@errors[message] || 0) + 1
    end
    
    
    
  private
    
    def print_invalid_params
      return if invalid_params.empty?
      status "\n\n\n#{("="*80)}\nExamples of invalid hashes\n#{("="*80)}"
      invalid_params.each do |model_name, errors|
        status "\n\n--#{model_name}#{("-"*(78 - model_name.length))}"
        errors.each do |error_message, hash|
          status "\n  #{error_message}:\n    #{hash.inspect}"
        end
      end
    end
    
    def print_messages(array, caption)
      return if array.empty?
      status "\n--#{caption}#{("-"*(78-caption.length))}\n\n"
      array.each do |message, count|
        stat "#{count} × #{message}"
      end
    end
    
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
