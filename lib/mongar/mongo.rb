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
      @connection = Mongo::Connection.new(host, port).db(database)
      return @connection if self.user.nil? || @connection.authenticate(user, password)
      @connection.close
      @connection = nil
    end
    
      # database 'mydb'
      #      user 'mongouser'
      #      password 'password'
      #      host '127.0.0.1'
      #      port 27017
      #      status_collection :statuses
  end
end