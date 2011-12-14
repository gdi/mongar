Mongar.configure do
  mongo :default do
    database 'integration_spec'
    
    status_collection 'stati'
  end
  
  replicate Domain do
    column :name do
      primary_index
    end
    
    column :client_id
    
    set_deleted_finder do |last_replicated_date|
      deleted_since last_replicated_date
    end

    set_updated_finder do |last_replicated_date|
      updated_since last_replicated_date
    end

    set_created_finder do |last_replicated_date|
      created_since last_replicated_date
    end
  end
end