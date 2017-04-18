require 'mongo'
class Mongar
  class Mongo
    autoload :Collection, 'mongar/mongo/collection'

    attr_reader :name

    # Supported connection attributes.
    [:database, :auth_database, :auth_mechanism, :user, :password, :host, :port, :ssl, :status_collection].each do |attr_name|
      define_method(attr_name) do |*args|
        val = args.first
        return instance_variable_get(:"@#{attr_name}") if val.nil?
        instance_variable_set(:"@#{attr_name}", val)
      end
    end

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

    def mongo_uri
      uri = "mongodb://#{@user and @password ? [@user, ':', @password, '@'].join : ''}#{@host}:#{@port}/#{@auth_database ? @auth_database : ''}#{@ssl ? '?ssl=true' : ''}"
    end

    def connection
      ::Mongo::Client.new(mongo_uri, :database => @database)
    end

    def connection!
      connection or raise StandardError, "Could not establish '#{name}' MongoDB connection for #{database} at #{host}:#{port}"
    end

    def db
      @db ||= connection!.database
      @db
    end

    def status_collection_accessor
      db[status_collection]
    end

    def time_on_server
      db.command(:eval => 'return new Date()').documents.first['retval']
    end
  end
end
