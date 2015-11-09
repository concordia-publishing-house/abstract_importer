require "objspace"

module AbstractImporter
  module Reporters
    class PerformanceReporter < BaseReporter
      attr_reader :sample_size

      def initialize(io, options={})
        super io
        @sample_size = options.fetch(:sample_size, 50)
        ObjectSpace.trace_object_allocations_start
      end


      def start_collection(collection)
        super
        @collection = collection
        @major_gc_runs = GC.stat[:major_gc_count]
        @i = 0
      end

      def finish_collection(collection, summary)
        @collection = nil
        return if @i.zero?
        find_objects_holding_onto_references_to_a collection.model
      end

      def record_created(record)
        print_stats if @i % sample_size == 0
        @i += 1
      end

      def record_failed(record, hash)
        print_stats if @i % sample_size == 0
        @i += 1
      end


      def print_stats
        stats = GC.stat
        objects = ObjectSpace.count_objects
        puts "gc[minor]: #{stats[:minor_gc_count]}, gc[major]: #{stats[:major_gc_count]}, objects: #{objects[:TOTAL] - objects[:FREE]}, memsize: #{(ObjectSpace.memsize_of_all / 1048576.0).round(3)}MB, #{collection.name}: #{ObjectSpace.each_object(collection.model).count}"
      end

    private
      attr_reader :collection

      def find_objects_holding_onto_references_to_a(model)
        GC.start

        # After GC.start, all models in this collection should be
        # garbage-collected unless there is a memory leak. Find one
        # of the uncollected objects and figure out what is holding
        # onto a reference to it.
        example = ObjectSpace.each_object(model).first
        unless example
          puts "\e[32mThere are no #{model.name.tableize.gsub("_", " ")} still in memory\e[0m"
          return
        end
        puts "\e[33mThere are #{ObjectSpace.each_object(model).count} #{model.name.tableize.gsub("_", " ")} still in memory\e[0m"

        example_klass = example.class.name
        example_id = example.object_id
        example = nil

        # Search through all objects to find ones that hold a reference
        # to the model that hasn't been garbage-collected.
        print "\e[90m"
        require "progressbar"
        pbar = ProgressBar.new("scanning", ObjectSpace.each_object.count)
        objects_of_holding = []
        ObjectSpace.each_object do |o|
          pbar.inc
          next if ObjectSpace.reachable_objects_from(o).none? { |oo| oo.object_id == example_id }

          message = "#{o.class.name}"
          case o
          when Array
            message << " (length: #{o.length})"
          when ActiveRecord::Associations::Association
            reflection = o.reflection
            message << " (#{reflection.active_record.name}##{reflection.macro}" <<
                       " :#{reflection.name})"
          end
          message << " [#{ObjectSpace.allocation_sourcefile(o)}" <<
                     ":#{ObjectSpace.allocation_sourceline(o)}]"

          objects_of_holding.push(message)
        end
        pbar.finish
        print "\e[0m"

        if objects_of_holding.none?
          puts "\e[95mNo objects are holding a reference to the first one\e[0m"
        else
          puts "\e[95m#{objects_of_holding.length} objects hold a reference to the first one:",
               "\e[35m#{objects_of_holding.join("\n")}\e[0m"
        end
      end

    end
  end
end
