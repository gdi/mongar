require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mongar::Replica" do
  before do
    @replica = Mongar::Replica.new
  end
  
  describe "#run" do
    before do
      class Client
        attr_accessor :name, :employee_count
        def initialize(args)
          args.each do |key, value|
            self.send(:"#{key}=", value)
          end
        end
      end
      
      @collection = Mongar::Mongo::Collection.new(:name => "clients")
      @replica = Mongar::Replica.new(:source => Client, :destination => @collection)
      @replica.column :name do
        primary_index
      end
      @replica.column :employee_count
      
      @mongo = Mongar::Mongo.new
      Mongar::Mongo.databases[:default] = @mongo
      
      @replica.stub!(:default_time_selector).and_return(@time)
      
      @last_replicated_time = Time.now - 86400
      @collection.stub!(:last_replicated_at).and_return(@last_replicated_time)
      
      @created_client1 = Client.new(:name => "Otis Co", :employee_count => 600)
    end
    
    context "requiring a full refresh" do
      before do
        @replica.stub!(:find).with(:created, Time.parse("1/1/1902 00:00:00")).and_return([@created_client1])
        @replica.stub!(:do_full_refresh?).and_return(true)
        
        @collection.stub!(:create_or_update!)
        @collection.stub!(:mark_all_items_pending_deletion!)
        @collection.stub!(:delete_all_items_pending_deletion!)
        @collection.stub!(:last_replicated_at=)
      end
      it "should create or update the items in the destination database" do
        @collection.should_receive(:create_or_update!).with({ :name => 'Otis Co'}, { :name => 'Otis Co', :employee_count => 600 })
        @replica.run
      end
      it "should mark all items pending delete" do
        @collection.should_receive(:mark_all_items_pending_deletion!)
        @replica.run
      end
      it "should delete items pending delete" do
        @collection.should_receive(:delete_all_items_pending_deletion!)
        @replica.run
      end
    end
    
    context "not requiring a full refresh" do
      before do
        @time = Time.parse("1/1/2011 00:00:00")
        Time.stub!(:now).and_return(@time)
        @replica.stub!(:default_time_selector).and_return(@time)
        
        @replica.stub!(:do_full_refresh?).and_return(false)
        
        @deleted_client1 = Client.new(:name => "Widget Co", :employee_count => 500)
        @replica.stub!(:find).with(:deleted, @last_replicated_time).and_return([@deleted_client1])
        
        @updated_client1 = Client.new(:name => "ABC Co", :employee_count => 700)
        @replica.stub!(:find).with(:updated, @last_replicated_time).and_return([@updated_client1])
        
        @replica.stub!(:find).with(:created, @last_replicated_time).and_return([@created_client1])

        @collection.stub!(:delete!)
        @collection.stub!(:create_or_update!)
        @collection.stub!(:update!)
        @collection.stub!(:last_replicated_at=)
      end
      
      it "should delete the items in the destination database" do
        @collection.should_receive(:delete!).with({ :name => 'Widget Co' })
        @replica.run
      end
      
      it "should create the items in the destination database" do
        @collection.should_receive(:create_or_update!).with({ :name => 'Otis Co' }, { :name => 'Otis Co', :employee_count => 600 })
        @replica.run
      end
      
      it "should update the items in the destination database" do
        @collection.should_receive(:update!).with({ :name => 'ABC Co' }, { :name => 'ABC Co', :employee_count => 700 })
        @replica.run
      end
      
      it "should set the last replicated at time to the time the run started" do
        @collection.should_receive(:last_replicated_at=).with(@time)
        @replica.run
      end
    end
  end
  
  describe "retrieving data from source object" do
    before do
      class Client
        attr_accessor :name, :employee_count, :something_else
        def initialize(args)
          args.each do |key, value|
            self.send(:"#{key}=", value)
          end
        end
      end

      @collection = Mongar::Mongo::Collection.new(:name => "clients")
      @replica = Mongar::Replica.new(:source => Client, :destination => @collection)
      @replica.column :name do
        primary_index
        transform :downcase
      end
      @replica.column :employee_count do
        transform do |value|
          value.nil? ? 0 : value
        end
      end

      @client1 = Client.new(:name => "Widget Co", :employee_count => 500)
      @client2 = Client.new(:name => "Widget 2 Co", :employee_count => nil)
    end
    
    describe "#source_object_to_hash" do
      it "should return a hash of all the columns" do
        @replica.source_object_to_hash(@client1).should == {:name => "widget co", :employee_count => 500}
      end
      it "should run any block transforms on the value" do
        @replica.source_object_to_hash(@client2)[:employee_count].should == 0
      end
      it "should return any symbol transforms on the value" do
        @replica.source_object_to_hash(@client1)[:name].should == 'widget co'
      end
    end
    
    describe "#source_object_to_primary_key_hash" do
      it "should return a hash of just the primary key column and value" do
        @replica.source_object_to_primary_key_hash(@client1).should == {:name => "widget co"}
      end
      it "should return any symbol transforms on the value" do
        @replica.source_object_to_primary_key_hash(@client1)[:name].should == 'widget co'
      end
    end
  end
  
  describe "#new" do
    before do
      @collection = Mongar::Mongo::Collection.new(:name => 'clients')
      @replica = Mongar::Replica.new(:destination => @collection)
    end
    it "should set the parent replica of the new collection" do
      @replica.destination.replica.should == @replica
    end
  end
  
  describe "#find" do
    before do
      class Client; end
      @replica.source = Client
      @date_time = Time.parse("1/1/2011 00:00:00")
      @replica.stub!(:source).and_return(Client)
    end
    
    context "default finders" do
      it "should execute the deleted_finder against the object given" do
        Client.should_receive(:find_every_with_deleted).with(:conditions => ["deleted_at > ?", @date_time])
        @replica.find(:deleted, @date_time)
      end
       it "should execute the created_finder against the object given" do
        Client.should_receive(:find).with(:all, :conditions => ["created_at > ? AND deleted_at IS NULL", @date_time])
        @replica.find(:created, @date_time)
      end
      it "should execute the updated_finder against the object given" do
        Client.should_receive(:find).with(:all, :conditions => ["updated_at > ? AND deleted_at IS NULL", @date_time])
        @replica.find(:updated, @date_time)
      end
    end
    
    context "custom finder blocks" do
      before do
        @replica.set_deleted_finder do |last_replicated_at|
          deleted_items_since(last_replicated_at)
        end
        
        @replica.set_created_finder do |last_replicated_at|
          created_items_since(last_replicated_at)
        end
        
        @replica.set_updated_finder do |last_replicated_at|
          updated_items_since(last_replicated_at)
        end
      end
      
      it "should call the custom deleted finder" do
        Client.should_receive(:deleted_items_since).with(@date_time)
        @replica.find(:deleted, @date_time)
      end
      
      it "should call the custom created finder" do
        Client.should_receive(:created_items_since).with(@date_time)
        @replica.find(:created, @date_time)
      end
      
      it "should call the custom updated finder" do
        Client.should_receive(:updated_items_since).with(@date_time)
        @replica.find(:updated, @date_time)
      end      
    end
    
    context "null finders" do
      before do
        @replica.no_deleted_finder
      end

      it "should not try to find anything" do
        Client.should_not_receive(:find_every_with_deleted)
        Client.should_not_receive(:find)
        @replica.find(:deleted, @date_time)
      end

      it "should return an empty array" do
        @replica.find(:deleted, @date_time).should == []
      end
    end
  end
  
  describe "#no_deleted_finder" do
    it "should set the deleted_finder to nil" do
      @replica.no_deleted_finder
      @replica.deleted_finder.should be_nil
    end
  end
  
  describe "#columns" do
    it "should default to an empty array" do
      @replica.columns.should be_empty
    end
  end
  
  describe "#column" do
    before do
      @block = lambda {}
      @mock_column = mock(Mongar::Column)
      Mongar::Column.stub!(:new).and_return(@mock_column)
    end
    it "should populate the columns array with the new column" do
      @replica.column :first_name
      @replica.columns.should == [@mock_column]
    end
    it "should create a new column with the name given" do
      Mongar::Column.should_receive(:new).with(:name => :first_name).and_return(@mock_column)
      @replica.column :first_name
    end
    it "should instance_eval the block given" do
      @mock_column.should_receive(:instance_eval).with(&@block)
      @replica.column :first_name, &@block
    end
  end
  
  describe "#primary_index" do
    before do
      @column = Mongar::Column.new(:name => :id)
      @column.primary_index
      
      @replica.columns = [@column]
    end
    it "should return the primary index column" do
      @replica.primary_index.should == @column
    end
  end
  
  describe "#full_refresh" do
    context "given an argument" do
      it "should take :every as an argument and save the time period in seconds" do
        @replica.full_refresh :every => 3601
        @replica.instance_variable_get(:"@full_refresh").should == 3601
      end
    
      it "should take :if as an argument and save the block" do
        @proc = Proc.new { |something| }
        @replica.full_refresh :if => @proc
        @replica.instance_variable_get(:"@full_refresh").should == @proc
      end
    end
    
    context "not given an argument" do
      before do
        @replica.instance_variable_set(:"@full_refresh", 3602)
      end
      it "should return the current full_refresh setting" do
        @replica.full_refresh.should == 3602
      end
    end
  end
  
  describe "#do_full_refresh?" do
    before do
      @time = Time.now
      @mongo = Mongar::Mongo.new
      @collection = Mongar::Mongo::Collection.new(:name => 'clients')
      @collection.stub!(:last_replicated_at).and_return(@time)
      @replica.stub!(:mongodb).and_return(@mongo)
      @replica.destination = @collection
    end
    
    context "given the full_refresh condition is a time period" do
      before do
        @replica.full_refresh :every => 3600
      end
      
      it "should return false if the time since the last refresh is less than 60 minutes" do
        @replica.do_full_refresh?.should be_false
      end
      it "should return true if the time since the last refresh is 60 minutes" do
        @collection.stub!(:last_replicated_at).and_return(@time - 3601)
        @replica.do_full_refresh?.should be_true
      end
      it "should return true if the last refresh time is nil" do
        @collection.stub!(:last_replicated_at).and_return(nil)
        @replica.do_full_refresh?.should be_true
      end
    end
    
    context "given the full_refresh condition is a proc" do
      before do
        @mock_source = mock(Object, :something_changed? => false)
        @replica.source = @mock_source
        @replica.full_refresh :if => Proc.new { |last_replicated_date|
          something_changed?(last_replicated_date)
        }
      end
      
      it "should return true if the proc evaluated in the source context is true" do
        @mock_source.should_receive(:something_changed?).with(@time).and_return(true)
        @replica.do_full_refresh?.should be_true
      end
      it "should return false if the proc evaluated in the source context is false" do
        @replica.do_full_refresh?.should be_false
      end
    end
  end
  
  describe "#mongodb_name" do
    it "should return the name given with #use_mongodb" do
      @replica.use_mongodb :other_mongo
      @replica.mongodb_name.should == :other_mongo
    end
    
    it "should default to :default if use_mongodb is never called" do
      @replica.mongodb_name.should == :default
    end
  end
  
  describe "#mongodb" do
    before do
      @fake_db = mock(Mongar::Mongo)
      Mongar::Mongo.databases[:default] = @fake_db
    end
    
    it "should return nil if it cannot find the mongo db by the name" do
      @replica.use_mongodb :something
      @replica.mongodb.should == nil
    end
    
    it "should return the mongo db based on the name" do
      @replica.mongodb.should == @fake_db
    end
  end
  
  describe "#db_time_selector" do
    before do
      @block = lambda {}
    end
    
    it "should default to nil" do
      @replica.db_time_selector.should be_nil
    end
    
    it "should set the time sql to something else given an argument" do
      @replica.db_time_selector &@block
      @replica.db_time_selector.should == @block
    end
  end
  
  describe "#current_time_on_database_server" do
    before do
      class Client; end
      @replica.source = Client
      @time = Time.now
    end
    context "default time selector" do
      it "should call default_time_selector" do
        @replica.should_receive(:default_time_selector).with(Client).and_return(@time)
        @replica.current_time_on_database_server.should == @time
      end
    end
    
    context "custom time selector" do
      before do
        @replica.db_time_selector do
          current_db_time
        end
      end
      
      it "should call the custom time selector function on the source class" do
        Client.should_receive(:current_db_time).and_return(@time)
        @replica.current_time_on_database_server.should == @time
      end
    end
  end
  
  describe "#default_time_selector" do
    before do
      class MockAdapters
        class MysqlAdapter
        end
      
        class Mysql2Adapter
        end
      
        class SQLServerAdapter
        end
      end
      
      @time = Time.now
    end
    
    context "mysql server backend" do
      before do
        @mock_connection = MockAdapters::MysqlAdapter.new
        @mock_source = mock(Object, :connection => @mock_connection)
        @mock_result = mock(Object, :fetch_row => [@time.to_s])
      end
      it "should run SELECT UTC_TIMESTAMP()" do
        @mock_connection.should_receive(:execute).with("SELECT UTC_TIMESTAMP()").and_return(@mock_result)
        @replica.default_time_selector(@mock_source).to_s.should == @time.to_s
      end
    end
    
    context "mysql server backend with mysql2 adapter" do
      before do
        @mock_connection = MockAdapters::Mysql2Adapter.new
        @mock_source = mock(Object, :connection => @mock_connection)
      end
      it "should run SELECT UTC_TIMESTAMP()" do
        @mock_connection.should_receive(:execute).with("SELECT UTC_TIMESTAMP()").and_return([[@time]])
        @replica.default_time_selector(@mock_source).should == @time
      end
    end
  
    context "sql server backend" do
      before do
        @mock_connection = MockAdapters::SQLServerAdapter.new
        @mock_source = mock(Object, :connection => @mock_connection)
      end
      it "should run SELECT getutcdate() as date" do
        @mock_connection.should_receive(:select_one).with("SELECT getutcdate() AS date").and_return({"date" => @time})
        @replica.default_time_selector(@mock_source).should == @time      
      end
    end
  end
end
