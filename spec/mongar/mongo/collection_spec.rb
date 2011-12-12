require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Mongar::Mongo::Collection" do
  before do
    @collection = Mongar::Mongo::Collection.new(:name => 'clients')
  end
  
  describe ".new" do
    it "should return a new collection" do
      @collection.should be_a_kind_of(Mongar::Mongo::Collection)
    end
  end
end
