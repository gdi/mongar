require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mongar::Replica" do
  before do
    @replica = Mongar::Replica.new
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
        @proc = Proc.new {}
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
    context "given the full_refresh condition is a time period" do
      before do
        @collection = Mongar::Mongo::Collection.new
        @replica.destination = @collection
        @replica.full_refresh :every => 3600
        @time = Time.now
        @collection.stub!(:last_refreshed_at).and_return(@time)
      end
      
      it "should return false if the time since the last refresh is less than 60 minutes" do
        @replica.do_full_refresh?.should be_false
      end
      it "should return true if the time since the last refresh is 60 minutes" do
        @collection.stub!(:last_refreshed_at).and_return(@time - 3601)
        @replica.do_full_refresh?.should be_true
      end
      it "should return true if the last refresh time is nil" do
        @collection.stub!(:last_refreshed_at).and_return(nil)
        @replica.do_full_refresh?.should be_true
      end
    end
    
    context "given the full_refresh condition is a proc" do
      before do
        @mock_source = mock(Object, :something_changed? => false)
        @replica.source = @mock_source
        @replica.full_refresh :if => Proc.new {
          something_changed?
        }
      end
      
      it "should return true if the proc evaluated in the source context is true" do
        @mock_source.stub!(:something_changed?).and_return(true)
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
end
