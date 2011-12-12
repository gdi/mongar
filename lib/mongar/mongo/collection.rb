class Mongar::Mongo
  class Collection
    attr_reader :name
    attr_accessor :replica
    
    def initialize(args = {})
      @name = args[:name]
    end
    
    def mongodb
      replica.mongodb
    end
    
    def connection
      mongodb.connection!
    end
    
  end
end