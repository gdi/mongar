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
    
    [:database, :auth_database, :auth_mechanism, :user, :password, :host, :port, :status_collection].each do |attr_name|
      define_method(attr_name) do |*args|
        val = args.first
        return instance_variable_get(:"@#{attr_name}") if val.nil?
        instance_variable_set(:"@#{attr_name}", val)
      end
    end
    
    def connection
      ::Mongo::Connection.new(host, port)
    end
    
    def connection!
      connection or raise StandardError, "Could not establish '#{name}' MongoDB connection for #{database} at #{host}:#{port}"
    end
    
    def db
      return @db unless @db.nil?
      @db = connection!.db(database.to_s)
      unless self.user.nil?
        db = self.auth_database.nil? ? @db : connection!.db(self.auth_database)
        mechanism = self.auth_mechanism || 'SCRAM-SHA-1'
        db.authenticate(user, password, :mechanism => mechanism)
      end
      @db
    end
    
    def status_collection_accessor
      db[status_collection]
    end
    
    def time_on_server
      db.eval("return new Date()")
    end
  end
end
