class Mongar::Mongo
  class Collection
    attr_reader :name
    
    def initialize(args = {})
      @name = args[:name]
    end
    
    def last_replicated_at
    end
    
    def last_replicated_at=(date)
    end
    
    def last_refreshed_at
    end
    
    def last_refreshed_at=(date)
    end
    
    def refreshed!
      last_refreshed_at = Time.now
    end
    
    def insert(doc)
      
    end
    
    def update(id_hash, doc)
      # coll.update({"_id" => doc["_id"]}, doc)
    end
    
    def delete(id_hash)
    end
  end
end