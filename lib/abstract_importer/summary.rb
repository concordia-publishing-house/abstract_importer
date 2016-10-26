module AbstractImporter
  class Summary < Struct.new(:total, :redundant, :created, :already_imported, :invalid, :ms, :skipped)

    def initialize(a=0, b=0, c=0, d=0, e=0, f=0, g=0)
      super(a,b,c,d,e,f,g)
    end

    def average_ms
      return nil if total == 0
      ms / total
    end

    def +(other)
      Summary.new(
        total + other.total,
        redundant + other.redundant,
        created + other.created,
        already_imported + other.already_imported,
        invalid + other.invalid,
        ms + other.ms,
        skipped + other.skipped)
    end

  end
end
