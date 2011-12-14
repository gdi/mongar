require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Mongar::Mongo::Collection" do
  after(:all) do
    # Completely clear out the database
    mongo = Mongar::Mongo.new(:name => :default, 
                              :database => :mongar_test)
    mongo.connection!.drop_database('mongar_test')
  end
  
  before do
    @mongo = Mongar::Mongo.new(:name => :default, 
                               :database => :mongar_test)
                               
    @mongo.db.collections.each do |collection|
        collection.remove
    end
    
    Mongar::Mongo.databases[:default] = @mongo
    @replica = Mongar::Replica.new(:mongodb_name => :default)
    @collection = Mongar::Mongo::Collection.new(:name => 'clients', :replica => @replica)
    
    @existing_key = { :id => 123 }
    @existing_document = { :id => 123, :name => 'Otis' }
    
    @new_key = { :id => 1234 }
    @new_document = { :id => 1234, :name => 'George' }
  end
  
  describe ".new" do
    it "should return a new collection" do
      @collection.should be_a_kind_of(Mongar::Mongo::Collection)
    end
  end
  
  describe "#database" do
    it "should not be nil" do
      @collection.database.should_not be_nil
    end
  end
  
  describe "#find" do
    before do
      @collection.create!({ :id => 2, :test => 1 })
    end
    it "should return nil if it can't find the document" do
      @collection.find({ :id => 1 }).should be_nil
    end
    it "should return the document found" do
      @collection.find({ :id => 2 }).should include({"id"=>2, "test"=>1})
    end
  end
  
  describe "#create_or_update" do
    it "should update an existing document" do
      @collection.create_or_update(@existing_key, @existing_document).should be_true
    end
    it "should create a new document" do
      @collection.create_or_update(@new_key, @new_document).should be_true
      @collection.find({:id => 1234}).should_not be_nil
    end
  end
  
  describe "#create_or_update!" do
    it "should call create_or_update and return true on success" do
      @collection.should_receive(:create_or_update).with({ :a => 1 }, { :a => 1, :b => 2 }).and_return(true)
      @collection.create_or_update!({ :a => 1 }, { :a => 1, :b => 2 }).should be_true
    end
    
    it "should call create_or_update and raise an error on failure" do
      @collection.stub!(:create_or_update).with({ :a => 1 }, { :a => 1, :b => 2 }).and_return(false)
      lambda { @collection.create_or_update!({ :a => 1 }, { :a => 1, :b => 2 }) }.should raise_error
    end
  end
  
  describe "#mark_all_items_pending_deletion" do
    before do
      @collection.create_or_update(@new_key, @new_document)
    end
    
    it "should mark every item with { :pending_deletion => true }" do
      @collection.mark_all_items_pending_deletion
      updated_doc = @collection.find(@new_key)
      updated_doc['pending_deletion'].should be_true
    end
  end
  
  describe "#mark_all_items_pending_deletion!" do
    it "should call mark_all_items_pending_deletion and return true on success" do
      @collection.should_receive(:mark_all_items_pending_deletion).and_return(true)
      @collection.mark_all_items_pending_deletion!({}, {}).should be_true
    end

    it "should call mark_all_items_pending_deletion and raise an error on failure" do
      @collection.stub!(:mark_all_items_pending_deletion).and_return(false)
      lambda { @collection.mark_all_items_pending_deletion!({}, {}) }.should raise_error
    end
  end
  
  describe "#delete_all_items_pending_deletion" do
    before do
      @collection.create!({ :id => 1, :test => 1, :pending_deletion => true })
      @collection.create!({ :id => 2, :test => 1, :pending_deletion => false })
      @collection.create!({ :id => 3, :test => 1 })
    end
    
    it "should delete all items where { :pending_deletion => true }" do
      @collection.delete_all_items_pending_deletion
      @collection.find({ :id => 1 }).should be_nil
    end
    it "should not delete items where { :pending_deletion => false }" do
      @collection.delete_all_items_pending_deletion
      @collection.find({ :id => 2 }).should_not be_nil
    end
    it "should not delete items where :pending_deletion key does not exist" do
      @collection.delete_all_items_pending_deletion
      @collection.find({ :id => 3 }).should_not be_nil
    end
  end
  
  describe "#delete_all_items_pending_deletion!" do
    it "should call delete_all_items_pending_deletion and return true on success" do
      @collection.should_receive(:delete_all_items_pending_deletion).and_return(true)
      @collection.delete_all_items_pending_deletion!({}, {}).should be_true
    end

    it "should call delete_all_items_pending_deletion and raise an error on failure" do
      @collection.stub!(:delete_all_items_pending_deletion).and_return(false)
      lambda { @collection.delete_all_items_pending_deletion!({}, {}) }.should raise_error
    end
  end
  
  describe "#delete" do
    it "should delete a document" do
      @collection.delete(@existing_key).should be_true
    end
    
    it "should return true even if the document didn't exist" do
      @collection.delete({ :id => 83838 }).should be_true
    end
  end
  
  describe "#delete!" do
    it "should call delete and return true on success" do
      @collection.should_receive(:delete).and_return(true)
      @collection.delete!({}, {}).should be_true
    end

    it "should call delete and raise an error on failure" do
      @collection.stub!(:delete).and_return(false)
      lambda { @collection.delete!({}, {}) }.should raise_error
    end
  end
  
  describe "#create" do
    it "should create a new document" do
      @collection.create(@new_document).should be_true
    end
  end
  
  describe "#create!" do
    it "should call create and return true on success" do
      @collection.should_receive(:create).and_return(true)
      @collection.create!({}, {}).should be_true
    end

    it "should call create and raise an error on failure" do
      @collection.stub!(:create).and_return(false)
      lambda { @collection.create!({}, {}) }.should raise_error
    end
  end
  
  describe "#update" do
    it "should update the document" do
      @collection.update(@existing_key, { :name => 'Phil' }).should be_true
    end
  end
  
  describe "#update!" do
    it "should call update and return true on success" do
      @collection.should_receive(:update).and_return(true)
      @collection.update!({}, {}).should be_true
    end

    it "should call update and raise an error on failure" do
      @collection.stub!(:update).and_return(false)
      lambda { @collection.update!({}, {}) }.should raise_error
    end
  end
  
  describe "#last_replicated_at" do
    it "should return the last replicated_at date" do
      response = @collection.last_replicated_at = Time.parse("1/1/2012 1:00:00")
      @collection.last_replicated_at.should == Time.parse("1/1/2012 1:00:00")
    end
    
    it "should return 1/1/1902 00:00:00 if there was no last_replicated_at" do
      @collection.last_replicated_at.should == Time.parse("1/1/1902 00:00:00")
    end
  end
end
