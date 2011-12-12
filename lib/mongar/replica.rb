class Mongar
  class Replica
    attr_accessor :source, :destination
    attr_accessor :mongodb_name
    attr_accessor :created_finder, :deleted_finder, :updated_finder
    attr_accessor :columns
    
    def initialize(args = {})
      self.source = args[:source]
      self.destination = args[:destination]
      self.mongodb_name = args[:mongodb_name] || :default
      self.columns = []
      
      self.deleted_finder = lambda do |last_replicated_at|
        find_every_with_deleted(:conditions => ["deleted_at > ?", last_replicated_at])
      end
      self.created_finder = Proc.new do |last_replicated_at|
        find(:all, :conditions => ["created_at > ? AND deleted_at IS NULL", last_replicated_at])
      end
      self.updated_finder = Proc.new do |last_replicated_at|
        find(:all, :conditions => ["updated_at > ? AND deleted_at IS NULL", last_replicated_at])
      end 
    end
    
    def column(name, &block)
      new_column = Mongar::Column.new(:name => name)
      new_column.instance_eval(&block) if block_given?
      self.columns << new_column
      new_column
    end
    
    def primary_index
      columns.find { |c| c.primary_index? }
    end
    
    def full_refresh(condition = nil)
      return @full_refresh if condition.nil?
      
      @full_refresh = if condition[:if]
        condition[:if]
      elsif condition[:every]
        condition[:every]
      else
        raise StandardError, 'You must specify either :if or :every as a condition for full refresh'
      end
    end
    
    def use_mongodb(name)
      self.mongodb_name = name
    end
    
    def mongodb_name=(val)
      @mongodb = nil
      @mongodb_name = val
    end
    
    def mongodb
      return nil unless mongodb_name
      @mongodb ||= Mongar::Mongo.databases[mongodb_name]
    end
    
    def do_full_refresh?
      if @full_refresh.nil?
        false
      elsif @full_refresh.is_a?(Proc)
        source.instance_exec &@full_refresh
      elsif destination.last_refreshed_at.nil?
        true
      else
        (Time.now - destination.last_refreshed_at) > @full_refresh
      end
    end
    
    def find(type, last_replicated_time)
      finder_function = self.send("#{type}_finder".to_sym)
      return [] if finder_function.nil?
      # execute the finder proc on the source object with an argument of the last replicated date/time
      source.instance_exec last_replicated_time, &finder_function
    end
    
    [:deleted, :created, :updated].each do |finder_type|
      define_method("set_#{finder_type}_finder".to_sym) do |&block|
        self.send("#{finder_type}_finder=".to_sym, block)
      end
      
      define_method("no_#{finder_type}_finder") do
        self.send("#{finder_type}_finder=".to_sym, nil)
      end
    end
  end
end