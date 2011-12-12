require 'linguistics'

class Mongar
  autoload :Replica, 'mongar/replica'
  autoload :Column, 'mongar/column'
  autoload :Mongo, 'mongar/mongo'

  Linguistics.use :en  
  
  attr_accessor :replicas, :status_collection
  
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
  
  def replicate(what, &block)
    if what.is_a?(Hash)
      source = what.keys.first
      destination = what.values.first
    else
      source = what
      destination = what.to_s.downcase.en.plural
    end
    
    destination = Mongar::Mongo::Collection.new(:name => :destination)
    
    self.replicas ||= []
    replica = Replica.new(:source => source, :destination => destination)
    replica.instance_eval(&block)
    self.replicas << replica
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
