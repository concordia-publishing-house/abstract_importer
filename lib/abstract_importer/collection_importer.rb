module AbstractImporter
  class CollectionImporter
    
    def initialize(importer, collection)
      @importer = importer
      @collection = collection
    end
    
    attr_reader :importer, :collection, :summary
    
    delegate :name,
             :table_name,
             :model,
             :scope,
             :options,
             :to => :collection
    
    delegate :dry_run?,
             :parent,
             :source,
             :reporter,
             :remap_foreign_key?,
             :id_map,
             :map_foreign_key,
             :to => :importer
    
    
    
    def perform!
      reporter.start_collection(self)
      prepare!
      
      invoke_callback(:before_all)
      summary.ms = Benchmark.ms do
        each_new_record &method(:process_record)
      end
      invoke_callback(:after_all)
      
      reporter.finish_collection(self, summary)
      summary
    end
    
    
    
    def prepare!
      @summary = Summary.new
      @mappings = prepare_mappings!
    end
    
    def prepare_mappings!
      mappings = []
      model.reflect_on_all_associations.each do |association|
        
        # We only want the associations where this record
        # has foreign keys that refer to another
        next unless association.macro == :belongs_to
        
        # We don't at this time support polymorphic associations
        # which would require extending id_map to take the foreign
        # type fields into account.
        #
        # Rails can't return `association.table_name` so easily
        # because `table_name` comes from `klass` and `klass`
        # isn't predetermined.
        
        if association.options[:polymorphic]
          depends_on = association.plural_name.to_sym # hackish?
        else
          depends_on = association.table_name.to_sym
        end
        foreign_key = association.foreign_key.to_sym
        
        # We support skipping some mappings entirely. I believe
        # this is largely to cut down on verbosity in the log
        # files and should be refactored to another place in time.
        next unless remap_foreign_key?(name, foreign_key)
        
        mappings << Proc.new do |hash|
          if hash.key?(foreign_key)
            hash[foreign_key] = map_foreign_key(hash[foreign_key], name, foreign_key, depends_on)
          else
            reporter.count_notice "#{name}.#{foreign_key} will not be mapped because it is not used"
          end
        end
      end
      mappings
    end
    
    
    
    
    
    def each_new_record
      source.public_send(name).each do |attrs|
        yield attrs.dup
      end
    end
    
    def process_record(hash)
      summary.total += 1
      
      if already_imported?(hash)
        summary.already_imported += 1
        return
      end
      
      remap_foreign_keys!(hash)
      
      if redundant_record?(hash)
        summary.redundant += 1
        return
      end
      
      if create_record(hash)
        summary.created += 1
      else
        summary.invalid += 1
      end
    rescue ::AbstractImporter::Skip
      summary.skipped += 1
    end
    
    
    
    
    
    def already_imported?(hash)
      id_map.contains? table_name, hash[:id]
    end
    
    def remap_foreign_keys!(hash)
      @mappings.each do |proc|
        proc.call(hash)
      end
    end
    
    def redundant_record?(hash)
      existing_record = invoke_callback(:finder, hash)
      if existing_record
        id_map.register(record: existing_record, legacy_id: hash[:id])
        true
      else
        false
      end
    end
    
    
    
    
    
    def create_record(hash)
      record = build_record(hash)
      
      return true if dry_run?
      
      invoke_callback(:before_create, record)
      
      # rescue_callback has one shot to fix things
      invoke_callback(:rescue, record) unless record.valid?
      
      if record.valid? && record.save
        invoke_callback(:after_create, hash, record)
        id_map << record
        
        reporter.record_created(record)
        true
      else
        
        reporter.record_failed(record, hash)
        false
      end
    end
    
    def build_record(hash)
      hash = invoke_callback(:before_build, hash) || hash
      
      legacy_id = hash.delete(:id)
      
      scope.build hash.merge(legacy_id: legacy_id)
    end
    
    
    
    def invoke_callback(callback, *args)
      callback_name = :"#{callback}_callback"
      callback = options.public_send(callback_name)
      return unless callback
      callback = importer.method(callback) if callback.is_a?(Symbol)
      callback.call(*args)
    end
    
  end
  
  class Skip < StandardError; end
  
end
