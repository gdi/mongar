require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mongar::Replica" do
  before do
    @column = Mongar::Column.new(:name => :first_name)
  end
  describe "#name" do
    it "should return the column name" do
      @column.name.should == :first_name
    end
  end
  describe "#transform" do
    it "should optionally take a symbol, and set transformation to a block that executes that procedure" do
      @column.transform :downcase
      @column.transform_this("Something").should == 'something'
    end
    it "should optionally take a block" do
      @column.transform do
        downcase
      end
      @column.transform_this("Something").should == 'something'
    end
    it "should take both a block and a symbol if you wish" do
      @column.transform :reverse do
        downcase
      end
      @column.transform_this("Something").should == 'gnihtemos'
    end
  end
  describe "#index" do
    before do
      @column.index
    end
    it "should set column#indexed? to true" do
      @column.indexed?.should be_true
    end
  end
  describe "#primary_index" do
    before do
      @column.primary_index
    end
    it "should set column#primary_index? to true" do
      @column.primary_index?.should be_true
    end
  end
end
