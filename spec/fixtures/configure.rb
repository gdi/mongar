Mongar.configure do
  mongo :default do
    database 'mydb'
    user 'mongouser'
    password 'password'
    host '127.0.0.1'
    port 27017
  end
  
  mongo :otherdb do
    database 'mydb'
    user 'mongouser'
    password 'password'
    
    status_collection :statuses
  end
  
  replicate Domain => 'domains' do
    use_mongodb :otherdb
    
    full_refresh :every => 60.minutes
    
    column :uri do
      transform :downcase
      index
    end
    
    column :allow_anyone_to_anyone_policy
  end
  
  replicate Client
  
  replicate EmailAddress do
    no_deleted_finder
    set_updated_finder do |last_replicated_date|
      find(:all, :conditions => ['something > ?', last_replicated_date])
    end
    set_created_finder do |last_replicated_date|
      created_scope(last_replicated_date)
    end
    
    full_refresh :if => Proc.new do
      # class eval'ed code
      any_changes?
    end
    
    column :address do
      transform do |value|
        # some code to perform on the value
      end
    end
  end
end