class Mongar::Mongo
  class Collection
    attr_reader :name, :logger
    attr_accessor :replica
    
    def initialize(args = {})
      @name = args[:name]
      @replica = args[:replica]
      @logger = args[:logger] || Logger.new(nil)
      @last_logged_activity = nil
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
      return Time.parse("1/1/1902 00:00:00") unless status && status['last_replicated_at']
      status['last_replicated_at']
    end
    
    def last_replicated_at=(date)
      logger.info "   * Updating #{name}.last_replicated_at to #{date}"
      status_collection.update({ :collection_name => name }, 
                               { '$set' => { :collection_name => name, :last_replicated_at => date } }, 
                               { :upsert => true })
    end
    
    def last_activity_at=(date)
      logger.debug "Saving #{name} last_activity_at to #{date}"
      status_collection.update({ :collection_name => name },
                               { '$set' => { :collection_name => name, :last_activity_at => date } },
                               { :upsert => true })
    end
    
    def log_activity
      return unless should_log_activity?
      logger.debug "Logging activity for #{name}"
      
      # should be able to set last_activity_at = new Date() but I can't figure out how to get
      # ruby's mongo library to evaluate it instead of setting it to the string "new Date()"
      status_collection.update({ :collection_name => name },
                               { '$set' => { :collection_name => name, :last_activity_at => mongodb.time_on_server } },
                               { :upsert => true })
      @last_logged_activity = Time.now
    end
    
    def should_log_activity?
      @last_logged_activity.nil? || Time.now - @last_logged_activity > 5
    end
    
    def last_activity_at
      status = status_collection.find_one({ :collection_name => name })
      return nil unless status && status['last_activity_at']
      status['last_activity_at']
    end
    
    def find(key)
      logger.debug "#{name}.find #{key.inspect}"
      collection.find_one(key)
    end
    
    def create(document)
      log_activity
      
      logger.debug "#{name}.create #{document.inspect}"
      !collection.insert(document).nil?
    end
    
    def delete(key)
      log_activity
      
      logger.debug "#{name}.delete #{key.inspect}"
      collection.remove(key, { :safe => true })
    end
    
    def update(key, document)
      log_activity
      
      logger.debug "#{name}.update #{key.inspect} with #{document.inspect}"
      collection.update(key, document, { :safe => true })
    end
    
    def create_or_update(key, document)
      log_activity
      
      logger.debug "#{name}.create_or_update #{key.inspect} with #{document.inspect}"
      
      collection.update(key, document, {:upsert => true, :safe => true})
    end
    
    def mark_all_items_pending_deletion
      log_activity
      
      logger.info "   * Marking all items in #{name} for pending deletion"
      
      collection.update({ '_id' => { '$exists' => true } }, { "$set" => { :pending_deletion => true } }, { :multi => true, :safe => true })
    end
    
    def delete_all_items_pending_deletion
      log_activity
      
      logger.info "   * Deleting all items in #{name} that are pending deletion"
      
      collection.remove({ :pending_deletion => true }, { :safe => true })
    end
    
    [:create, :delete, :update, :create_or_update, :mark_all_items_pending_deletion, :delete_all_items_pending_deletion].each do |method_name|
      define_method(:"#{method_name}!") do |*args|
        result = self.send(method_name, *args)
        raise StandardError, "#{method_name} returned #{result.inspect}" unless result == true || result['err'].nil?
        result
      end
    end
  end
end