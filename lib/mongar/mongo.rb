require 'mongo'
class Mongar
  class Mongo
    autoload :Collection, 'mongar/mongo/collection'
    
    attr_reader :name
    
    class << self
      def databases
        @databases ||= {}
      end
    end
    
    def initialize(args = {})
      args.each do |key, value|
        instance_variable_set(:"@#{key}", value)
      end
      
      @host ||= '127.0.0.1'
      @port ||= 27017
      @status_collection ||= 'statuses'
    end
    
    [:database, :user, :password, :host, :port, :status_collection].each do |attr_name|
      define_method(attr_name) do |val = nil|
        return instance_variable_get(:"@#{attr_name}") if val.nil?
        instance_variable_set(:"@#{attr_name}", val)
      end
    end
    
    def connection
      @connection = ::Mongo::Connection.new(host, port)
      return @connection if self.user.nil? || @connection.authenticate(user, password)
      @connection.close
      @connection = nil
    end
    
    def connection!
      connection or raise StandardError, "Could not establish '#{name}' MongoDB connection for #{database} at #{host}:#{port}"
    end
    
    def db
      @db ||= connection!.db(database.to_s)
    end
    
    def status_collection_accessor
      db[status_collection]
    end
    
    def last_replicated_at
      #connection!.find(:collection_name => name).first
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
  end
end