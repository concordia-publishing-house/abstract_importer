require 'abstract_importer/import_options'
require 'abstract_importer/import_plan'
require 'abstract_importer/reporter'
require 'abstract_importer/collection'
require 'abstract_importer/collection_importer'
require 'abstract_importer/id_map'
require 'abstract_importer/summary'


module AbstractImporter
  class Base
    
    class << self
      def import
        yield @import_plan = ImportPlan.new
      end
      
      attr_reader :import_plan
    end
    
    
    
    def initialize(parent, source, options={})
      @source       = source
      @parent       = parent
      
      io            = options.fetch(:io, $stderr)
      @reporter     = Reporter.new(io, Rails.env.production?)
      @dry_run      = options.fetch(:dry_run, false)
      
      @id_map       = IdMap.new
      @results      = {}
      @import_plan  = self.class.import_plan.to_h
      @atomic       = options.fetch(:atomic, false)
      @collections  = []
    end
    
    attr_reader :source, :parent, :reporter, :id_map, :results
    
    def atomic?
      @atomic
    end
    
    def dry_run?
      @dry_run
    end
    
    
    
    
    
    def perform!
      reporter.start_all(self)
      
      ms = Benchmark.ms do
        setup
      end
      reporter.finish_setup(ms)
      
      ms = Benchmark.ms do
        with_transaction do
          collections.each &method(:import_collection)
        end
      end
      
      teardown
      reporter.finish_all(self, ms)
      results
    end
    
    def setup
      verify_source!
      verify_parent!
      instantiate_collections!
      prepopulate_id_map!
    end
    
    def import_collection(collection)
      results[collection.name] = CollectionImporter.new(self, collection).perform!
    end
    
    def teardown
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
      id_map.apply!(legacy_id, depends_on)
    rescue IdMap::IdNotMappedError
      record_no_id_in_map_error(legacy_id, plural, foreign_key, depends_on)
      nil
    end
    
    
    
    
    
  private
    
    attr_reader :collections, :import_plan
    
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
    
    def prepopulate_id_map!
      collections.each do |collection|
        query = collection.scope.where("#{collection.table_name}.legacy_id IS NOT NULL")
        map = values_of(query, :id, :legacy_id) \
          .each_with_object({}) { |(id, legacy_id), map| map[legacy_id] = id }
        
        id_map.init collection.table_name, map
      end
    end
    
    def values_of(query, *columns)
      if Rails.version < "4.0.0"
        query = query.select(columns.map { |column| "#{query.table_name}.#{column}" }.join(", "))
        ActiveRecord::Base.connection.select_rows(query.to_sql)
      else
        query.pluck(*columns)
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
    
  end
end
