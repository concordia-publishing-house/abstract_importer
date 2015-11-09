module AbstractImporter
  class ImportPlan

    def initialize
      @plan = {} # <-- requires Ruby 1.9's ordered hash
    end

    def to_h
      @plan.dup
    end

    def method_missing(plural, &block)
      @plan[plural] = block
    end

  end
end
