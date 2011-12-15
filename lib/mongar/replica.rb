class Mongar
  class Replica
    include Mongar::Logger
    
    attr_accessor :source, :destination, :log_level
    attr_accessor :mongodb_name
    attr_accessor :created_finder, :deleted_finder, :updated_finder, :db_time_selector
    attr_accessor :columns
    
    def initialize(args = {})
      self.log_level = args[:log_level]
      self.source = args[:source]
      self.destination = args[:destination]
      self.mongodb_name = args[:mongodb_name] || :default
      self.columns = []
      
      self.destination.replica = self if self.destination
      
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
    
    def run
      time = current_time_on_database_server
      
      if do_full_refresh?
        info "Running full refresh on Replica #{source.to_s} to #{destination.name}"
        
        destination.mark_all_items_pending_deletion!
        
        run_sync_for([:created_or_updated], Time.parse('1/1/1902 00:00:00'))
        
        destination.delete_all_items_pending_deletion!
      else
        last_replicated_at = destination.last_replicated_at
        
        info "Running incremental replication on Replica #{source.to_s} to #{destination.name} from #{last_replicated_at}"
        
        run_sync_for([:deleted, :created_or_updated, :updated], last_replicated_at)
      end
      destination.last_replicated_at = time
    end
    
    def run_sync_for(types, last_replicated_at)
      # find deleted
      find(:deleted, last_replicated_at).each do |deleted_item|
        destination.delete! source_object_to_primary_key_hash(deleted_item)
      end if types.include?(:deleted)
      
      # find created
      find(:created, last_replicated_at).each do |created_item|
        destination.create! source_object_to_hash(created_item)
      end if types.include?(:created)
      
      # find created & updated
      find(:created, last_replicated_at).each do |created_item|
        destination.create_or_update! source_object_to_primary_key_hash(created_item), source_object_to_hash(created_item)
      end if types.include?(:created_or_updated)
      
      # find updated
      find(:updated, last_replicated_at).each do |updated_item|
        destination.update! source_object_to_primary_key_hash(updated_item), source_object_to_hash(updated_item)
      end if types.include?(:updated)
    end
    
    def source_object_to_hash(object)
      columns.inject({}) do |hash, column|
        name = column.name.to_sym
        hash[name] = column.transform_this(object.send(name))
        hash
      end
    end
    
    def source_object_to_primary_key_hash(object)
      column = primary_index
      { column.name => column.transform_this(object.send(column.name.to_sym)) }
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
    
    def do_full_refresh?(last_replicated_time = nil)
      last_replicated_time ||= destination.last_replicated_at
      
      if @full_refresh.nil?
        false
      elsif @full_refresh.is_a?(Proc)
        source.instance_exec last_replicated_time, &@full_refresh
      elsif last_replicated_time.nil?
        true
      else
        (Time.now - last_replicated_time) > @full_refresh
      end
    end
    
    def find(type, last_replicated_time)
      finder_function = self.send("#{type}_finder".to_sym)
      return [] if finder_function.nil?
      # execute the finder proc on the source object with an argument of the last replicated date/time
      source.instance_exec(last_replicated_time, &finder_function) || []
    end
    
    [:deleted, :created, :updated].each do |finder_type|
      define_method("set_#{finder_type}_finder".to_sym) do |&block|
        self.send("#{finder_type}_finder=".to_sym, block)
      end
      
      define_method("no_#{finder_type}_finder") do
        self.send("#{finder_type}_finder=".to_sym, nil)
      end
    end
    
    def db_time_selector &block
      return @db_time_selector unless block_given?
      
      @db_time_selector = block
    end
    
    def default_time_selector(object)
      adapter = object.connection.class.to_s
      adapter = $1 if adapter =~ /::([^:]+)$/
      
      time = if adapter == 'MysqlAdapter'
        Time.parse(object.connection.execute("SELECT UTC_TIMESTAMP()").fetch_row.first)
      elsif adapter == 'Mysql2Adapter'
        object.connection.execute("SELECT UTC_TIMESTAMP()").first.first
      elsif adapter == 'SQLServerAdapter'
        object.connection.select_one("SELECT getutcdate() AS date")['date']
      end
      
      time.is_a?(Time) ? time : nil
    end
    
    def current_time_on_database_server
      @db_time_selector.nil? ? default_time_selector(source) : source.instance_exec(&@db_time_selector)
    end
  end
end
