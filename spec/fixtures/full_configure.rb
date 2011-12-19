Mongar.configure do
  # Currently we only log to STDOUT, we have plans to use a
  # plans to use a configurable logger.
  # Valid log levels are :info and :debug
  log_level :debug
  
  mongo :default do
    database 'mydb'
  end

  mongo :otherdb do
    database 'myotherdb'
    user 'mongouser'
    password 'password'
    host '127.0.0.1'
    port 27017
    
    # By default Mongar uses the 'statuses' collection to
    # keep track of the last replicated times, you can specify
    # a custom collection name
    status_collection :stati
  end
  
  # Minimal replica config to replicate the Domain model
  # to the 'domains' mongo collection on the mongo db defined
  # in the :default config above

  replicate Domain do
    column :name do
      primary_index
    end
    
    column :client_id
  end

  # Customized replica config to replicate the Client
  # model to the 'customers' mongo collection on the db
  # defined in the :otherdb config above
  
  replicate Client => ['otherdb.clients', { :someotherdb => 'clients' }, 'clients'] do
    # By default, Mongar will try to determine the time on the
    # backend database. The supported ActiveRecord database adapters
    # are MysqlAdapter, Mysql2Adapter, and SQLServerAdapter.
    # You can use a custom function to determine the time on Client's
    # backend database
    db_time_selector do
      # this will run Client#get_db_time
      get_db_time
    end
    
    # Items are never deleted
    no_deleted_finder
    
    # Customize your updated record finder.  The block is 
    # run in the source class context
    set_updated_finder do |last_replicated_date|
      find(:all, :conditions => ['something > ?', last_replicated_date])
    end
    
    # Custom created item finder
    set_created_finder do |last_replicated_date|
      created_scope(last_replicated_date)
    end
  
    # Run a full refresh of all items in the database based
    # a condition returned by the Proc
    full_refresh :if => Proc.new do |last_replicated_date|
      # class eval'ed code
      any_changes_since?(last_replicated_date)
    end
    
    # You can also refresh every N seconds
    # full_refresh :every => 3600
    
    # Define your columns
    column :id do
      # The 'primary index' column is used to find items in the mongo collection
      primary_index
    end
    
    column :tag do
      # Run the procedure :downcase on the value of Client#tag
      transform :downcase
    end
    
    column :employee_count do
      # Run a block transformation on the value of Client#employee_count
      transform do |value|
        value.nil? ? 0 : value
      end
    end
  end
end