require "rubygems"

require "simplecov"
SimpleCov.start do
  add_filter "test/"
end

require "rails"
require "rails/test_help"
require "turn"
require "pry"
require "rr"
require "database_cleaner"
require "abstract_importer"
require "shoulda/context"
require "active_record"
require "support/mock_data_source"
require "support/mock_objects"



ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:",
  :verbosity => "quiet")

load File.join(File.dirname(__FILE__), "support", "schema.rb")



DatabaseCleaner.strategy = :transaction
$io = ENV['VERBOSE'] ? $stderr : File.open("/dev/null", "w")



class ActiveSupport::TestCase
  
  setup do
    DatabaseCleaner.start
    
    @data_source = MockDataSource.new
    @klass = Class.new(AbstractImporter::Base)
    @account = Account.create!
    @options = {}
  end
  
  teardown do
    DatabaseCleaner.clean
    @importer = nil
  end
  
protected
  
  attr_reader :account, :results, :data_source, :options
  
  def plan(&block)
    @klass.import(&block)
  end
  
  def depends_on(*args)
    @klass.depends_on(*args)
  end
  
  def import!
    @results = importer.perform!
  end
  
  def importer
    @importer ||= @klass.new(@account, @data_source, options.merge(io: $io))
  end
  
end
