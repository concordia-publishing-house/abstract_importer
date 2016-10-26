require "active_support/core_ext/module/delegation"
require "abstract_importer/import_options"
require "abstract_importer/import_plan"
require "abstract_importer/reporters"
require "abstract_importer/collection"
require "abstract_importer/collection_importer"
require "abstract_importer/id_map"
require "abstract_importer/summary"


module AbstractImporter
  class Base

    class << self
      def import
        yield @import_plan = ImportPlan.new
      end

      def depends_on(*dependencies)
        @dependencies = dependencies
      end

      attr_reader :import_plan, :dependencies
    end



    def initialize(parent, source, options={})
      @source       = source
      @parent       = parent

      io            = options.fetch(:io, $stderr)
      @reporter     = default_reporter(options, io)
      @dry_run      = options.fetch(:dry_run, false)

      @id_map       = IdMap.new
      @import_plan  = self.class.import_plan.to_h
      @atomic       = options.fetch(:atomic, false)
      @strategies   = options.fetch(:strategy, {})
      @skip         = Array(options[:skip])
      @only         = Array(options[:only]) if options.key?(:only)
      @collections  = []

      verify_source!
      verify_parent!
      instantiate_collections!

      @collection_importers = []
      collections.each do |collection|
        next if skip? collection
        @collection_importers.push CollectionImporter.new(self, collection)
      end
    end

    attr_reader :source,
                :parent,
                :reporter,
                :id_map,
                :collections,
                :import_plan,
                :skip,
                :only,
                :collection_importers

    def atomic?
      @atomic
    end

    def dry_run?
      @dry_run
    end





    def perform!
      {}.tap do |results|
        reporter.start_all(self)

        ms = Benchmark.ms do
          setup
        end
        reporter.finish_setup(self, ms)

        ms = Benchmark.ms do
          with_transaction do
            collection_importers.each do |importer|
              results[importer.name] = importer.perform!
            end
          end
        end

        ms = Benchmark.ms do
          teardown
        end
        reporter.finish_teardown(self, ms)

        reporter.finish_all(self, ms)
      end
    end

    def setup
      prepopulate_id_map!
    end

    def count_collection(collection)
      collection_name = collection.respond_to?(:name) ? collection.name : collection
      collection_counts[collection_name]
    end

    def collection_counts
      @collection_counts ||= Hash.new do |counts, collection_name|
        counts[collection_name] = if self.source.respond_to?(:"#{collection_name}_count")
          self.source.public_send(:"#{collection_name}_count")
        else
          self.source.public_send(collection_name).count
        end
      end
    end

    def teardown
    end

    def skip?(collection)
      return true if skip.member?(collection.name)
      return true if only && !only.member?(collection.name)
      false
    end

    def strategy_for(collection_importer)
      collection = collection_importer.collection
      strategy_name = @strategies.fetch collection.name, :default
      strategy_options = {}
      if strategy_name.is_a?(Hash)
        strategy_options = strategy_name
        strategy_name = strategy_name[:name]
      end
      strategy_klass = AbstractImporter::Strategies.const_get :"#{strategy_name.capitalize}Strategy"
      strategy_klass.new(collection_importer, strategy_options)
    end





    def describe_source
      source.to_s
    end

    def describe_destination
      parent.to_s
    end





    def remap_foreign_key?(plural, foreign_key)
      true
    end

    def map_foreign_key(legacy_id, plural, foreign_key, depends_on)
      return nil if legacy_id.nil?
      collection = collections.find { |collection| collection.name == depends_on } ||
                   dependencies.find { |collection| collection.name == depends_on }
      return legacy_id if collection && !collection.has_legacy_id?
      id_map.apply!(legacy_id, depends_on)
    rescue IdMap::IdNotMappedError
      record_no_id_in_map_error(legacy_id, plural, foreign_key, depends_on)
      nil
    end





  private

    def verify_source!
      import_plan.keys.each do |collection|
        next if source.respond_to?(collection)

        raise "#{source.class} does not respond to `#{collection}`; " <<
              "but #{self.class} plans to import records with that name"
      end
    end

    def verify_parent!
      import_plan.keys.each do |collection|
        next if parent.respond_to?(collection)

        raise "#{parent.class} does not have a collection named `#{collection}`; " <<
              "but #{self.class} plans to import records with that name"
      end
    end

    def instantiate_collections!
      @collections = import_plan.map do |name, block|
        reflection = parent.class.reflect_on_association(name)
        model = reflection.klass
        table_name = model.table_name
        scope = parent.public_send(name)

        options = ImportOptions.new
        instance_exec(options, &block) if block

        Collection.new(name, model, table_name, scope, options)
      end
    end

    def dependencies
      @dependencies ||= Array(self.class.dependencies).map do |name|
        reflection = parent.class.reflect_on_association(name)
        model = reflection.klass
        table_name = model.table_name
        scope = parent.public_send(name)

        Collection.new(name, model, table_name, scope, nil)
      end
    end

    def prepopulate_id_map!
      (collections + dependencies).each do |collection|
        next unless collection.has_legacy_id?
        id_map.init collection.table_name, collection.scope
          .where("#{collection.table_name}.legacy_id IS NOT NULL")
      end
    end



    def record_no_id_in_map_error(legacy_id, plural, foreign_key, depends_on)
      reporter.count_notice "#{plural}.#{foreign_key} will be nil: a #{depends_on.to_s.singularize} with the legacy id #{legacy_id} was not mapped."
    end



    def with_transaction(&block)
      if atomic?
        ActiveRecord::Base.transaction(requires_new: true, &block)
      else
        block.call
      end
    end

    def default_reporter(options, io)
      reporter = options.fetch(:reporter, ENV["IMPORT_REPORTER"])
      return reporter if reporter.is_a?(AbstractImporter::Reporters::BaseReporter)

      case reporter.to_s.downcase
      when "none"        then Reporters::NullReporter.new(io)
      when "performance" then Reporters::PerformanceReporter.new(io)
      when "debug"       then Reporters::DebugReporter.new(io)
      when "dot"         then Reporters::DotReporter.new(io)
      else
        if ENV["RAILS_ENV"] == "production"
          Reporters::DebugReporter.new(io)
        else
          Reporters::DotReporter.new(io)
        end
      end
    end

  end
end
