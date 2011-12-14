class Domain
  attr_accessor :name, :client_id
  attr_accessor :created_at, :updated_at, :deleted_at
  
  def initialize(args = {})
    args.each do |key, value|
      self.send(:"#{key}=", value)
    end
    self.created_at = Time.now
  end
  
  def name=(val)
    self.updated_at = Time.now
    @name = val
  end
  
  def client_id=(val)
    self.updated_at = Time.now
    @client_id = val
  end
  
  class << self
    def create(args)
      @@items ||= []
      d = Domain.new(args)
      @@items << d
      d
    end
    
    def deleted_since(last_replicated_date)
      last_replicated_date ||= Time.parse("1/1/1900 00:00:00")
      #puts "Deleted Since: #{last_replicated_date} #{@@items.length}"
        
      @@items.find_all { |d| d.deleted_at && d.deleted_at > last_replicated_date }
    end
    
    def created_since(last_replicated_date)
      last_replicated_date ||= Time.parse("1/1/1900 00:00:00")
      #puts "Created Since: #{last_replicated_date}"
      
      @@items.find_all { |d| !d.deleted_at && d.created_at && d.created_at > last_replicated_date }
    end
    
    def updated_since(last_replicated_date)
      last_replicated_date ||= Time.parse("1/1/1900 00:00:00")
      #puts "Updated Since: #{last_replicated_date}"
      
      @@items.find_all { |d| !d.deleted_at && d.updated_at && d.updated_at > last_replicated_date }
    end
  end
  
  def destroy
    self.deleted_at = Time.now
    #puts "I was deleted at #{deleted_at}"
  end
end

class Client
end

class EmailAddress
end
