class Mongar
  class Column
    attr_accessor :name, :transformation, :is_indexed, :is_primary_index
    
    def initialize(args = {})
      self.name = args[:name]
      self.transformation = lambda {}
      self.is_indexed = false
      self.is_primary_index = false
    end
    
    def transform(proc_name = nil, &block)
      self.transformation = lambda do
        result = self
        result = instance_exec(&block) if block_given?
        result = result.send(proc_name) if proc_name
        result
      end
    end
    
    def transform_this(object)
      object.instance_exec(&transformation)
    end
    
    def index
      self.is_indexed = true
    end
    
    def primary_index
      self.is_primary_index = true
    end
    
    def indexed?
      self.is_indexed
    end
    
    def primary_index?
      self.is_primary_index
    end
  end
end
