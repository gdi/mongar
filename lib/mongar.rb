require 'linguistics'
require 'logger'

class Mongar
  class UnknownLogLevel < StandardError; end
  
  autoload :Replica, 'mongar/replica'
  autoload :Column, 'mongar/column'
  autoload :Mongo, 'mongar/mongo'

  Linguistics.use :en  
  
  attr_accessor :replicas, :status_collection, :log_level, :logger
  
  class << self
    def configure &block
      mongar = self.new
      mongar.instance_eval(&block)
      mongar
    end
  end
  
  def initialize
    self.log_level = :debug
    self.logger = Logger.new(STDOUT)
    self.replicas = []
  end
  
  def run
    replicas.each do |replica|
      replica.run
    end
  end
  
  def replicate(what, &block)
    if what.is_a?(Hash)
      source = what.keys.first
      destinations = what.values.first
    else
      source = what
      destinations = what.to_s.downcase.en.plural
    end  
    destinations = [destinations] unless destinations.is_a?(Array)
    
    self.replicas ||= []
    
    destinations.each do |destination|
      database = nil
      collection = if destination.is_a?(Hash)
        database = destination.keys.first
        Mongar::Mongo::Collection.new(:name => destination.values.first, :logger => logger)
      else
        Mongar::Mongo::Collection.new(:name => destination, :logger => logger)
      end
      
      replica = Replica.new(:source => source, :destination => collection, :mongodb_name => database, :logger => logger)
      replica.instance_eval(&block)
      self.replicas << replica
    end
  end
  
  def mongo(name, &block)
    mongo_db = Mongar::Mongo.new(:name => name)
    mongo_db.instance_eval(&block)
    Mongar::Mongo.databases[name] = mongo_db
    mongo_db
  end
  
  def set_status_collection(val)
    self.status_collection = val
  end

  def log_level(level = nil)
    return @log_level if level.nil?
    unless [:fatal, :error, :warn, :info, :debug].include?(level)
      raise UnknownLogLevel, "Log level #{level} is unknown. Valid levels are :fatal, :error, :warn, :info, :debug" 
    end
    @log_level = level
    set_log_level
  end
  
  def log(destination)
    if destination == :stdout
      @logger = Logger.new(STDOUT)
    else
      @logger = Logger.new(destination, 'daily')
    end
    set_log_level
  end
  
  def set_log_level
    @logger.level = Logger.const_get(@log_level.to_s.upcase)
  end
end
