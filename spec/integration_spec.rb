require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'sources'))

describe "Mongar" do
  before(:all) do
    mongo = Mongar::Mongo.new(:name => :default, 
                              :database => :integration_spec)
    mongo.connection!.drop_database('integration_spec')
  end
  describe "run" do
    before do
      config_path = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'configure.rb'))
      @mongar = eval(File.read(config_path))
      
      @collection = Mongar::Mongo.databases[:default].db['domains']
    end
    
    it "should add, delete, and update items properly" do
      # inserts
      domain = Domain.create(:name => "test.com", :client_id => 1)
      @mongar.run
      @collection.find_one({ :name => 'test.com' }).should include({'name' => 'test.com', 'client_id' => 1})
      
      # updates
      sleep 1
      domain.client_id = 2
      @mongar.run
      @collection.find_one({ :name => 'test.com' }).should include({'name' => 'test.com', 'client_id' => 2})

      # deletes
      sleep 1
      domain.destroy
      @mongar.run
      @collection.find_one({:name => "test.com"}).should be_nil
      
      collection = Mongar::Mongo.databases[:default].db['stati']
      collection.find_one({ :collection_name => 'domains' }).should_not be_nil
    end
    
    it "should write to the stati collection for status" do
      
      
    end
  end
end
