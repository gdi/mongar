require 'linguistics'

class Mongar
  autoload :Replica, 'mongar/replica'
  autoload :Column, 'mongar/column'
  autoload :Mongo, 'mongar/mongo'
  autoload :Logger, 'mongar/logger'

  include Mongar::Logger

  Linguistics.use :en  
  
  attr_accessor :replicas, :status_collection, :log_level
  
  class << self
    def configure &block
      mongar = self.new
      mongar.instance_eval(&block)
      mongar
    end
  end
  
  def initialize
    self.replicas = []
  end
  
  def log_level(level = nil)
    return @log_level if level.nil?
    @log_level = level
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
    
    destinations = destinations.collect do |dest_def|
      if dest_def.is_a?(Hash)
        Mongar::Mongo::Collection.new(:name => dest_def.values.first, :mongodb_name => dest_def.keys.first, :log_level => log_level)
      else
        Mongar::Mongo::Collection.new(:name => dest_def, :log_level => log_level)
      end
    end
    
    self.replicas ||= []
    
    destinations.each do |destination|
      replica = Replica.new(:source => source, :destination => destination, :log_level => log_level)
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
end
