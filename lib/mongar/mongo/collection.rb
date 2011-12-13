class Mongar::Mongo
  class Collection
    attr_reader :name
    attr_accessor :replica
    
    def initialize(args = {})
      @name = args[:name]
      @replica = args[:replica]
    end
    
    def mongodb
      replica.mongodb
    end
    
    def connection
      mongodb.connection!
    end
    
    def database
      mongodb.db
    end
    
    def collection
      database[name]
    end
    
    def status_collection
      mongodb.status_collection_accessor
    end
    
    def last_replicated_at
      status = status_collection.find_one({ :collection_name => name })
      return nil unless status
      status['last_replicated_at']
    end
    
    def last_replicated_at=(date)
      status_collection.update({ :collection_name => name }, 
                               { :collection_name => name, :last_replicated_at => date }, 
                               { :upsert => true })
    end
    
    def find(key)
      collection.find_one(key)
    end
    
    def create(document)
      !collection.insert(document).nil?
    end
    
    def delete(key)
      collection.remove(key)
    end
    
    def update(key, document)
      collection.update(key, document)
    end
    
    def create_or_update(key, document)   
      collection.update(key, document, {:upsert => true})
    end
    
    def mark_all_items_pending_deletion
      collection.update({ '_id' => { '$exists' => true } }, { "$set" => { :pending_deletion => true } }, { :multi => true })
    end
    
    def delete_all_items_pending_deletion
      collection.remove({ :pending_deletion => true })
    end
    
    [:create, :delete, :update, :create_or_update, :mark_all_items_pending_deletion, :delete_all_items_pending_deletion].each do |method_name|
      define_method(:"#{method_name}!") do |*args|
        result = self.send(method_name, *args)
        raise StandardError if result != true
        result
      end
    end
  end
end