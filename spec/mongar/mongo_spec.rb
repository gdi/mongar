require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Mongar::Mongo" do
  before do
    @mongo = Mongar::Mongo.new(:name => :somedb, 
                               :database => :mydb, 
                               :user => 'mongouser',
                               :password => 'password',
                               :host => '127.0.0.99',
                               :port => 9999,
                               :status_collection => 'stati')
  end
  
  describe "#database" do
    it "should set the database name if an argument is passed" do
      @mongo.database(:something)
      @mongo.instance_variable_get(:"@database").should == :something
    end
    
    it "should return the database name if no argument is passed" do
      @mongo.database.should == :mydb
    end
  end
  
  describe "#user" do
    it "should set the user if an argument is passed" do
      @mongo.user(:something)
      @mongo.instance_variable_get(:"@user").should == :something
    end
    
    it "should return the user if no argument is passed" do
      @mongo.user.should == 'mongouser'
    end
  end
  
  describe "#password" do
    it "should set the password if an argument is passed" do
      @mongo.password(:something)
      @mongo.instance_variable_get(:"@password").should == :something
    end
    
    it "should return the password if no argument is passed" do
      @mongo.password.should == 'password'
    end
  end
  
  describe "#host" do
    it "should set the host if an argument is passed" do
      @mongo.host(:something)
      @mongo.instance_variable_get(:"@host").should == :something
    end
    
    it "should return the host if no argument is passed" do
      @mongo.host.should == '127.0.0.99'
    end
    
    it "should default to 127.0.0.1" do
      Mongar::Mongo.new.host.should == '127.0.0.1'
    end
  end
  
  describe "#port" do
    it "should set the port if an argument is passed" do
      @mongo.port(:something)
      @mongo.instance_variable_get(:"@port").should == :something
    end
    
    it "should return the port if no argument is passed" do
      @mongo.port.should == 9999
    end
    
    it "should default to 27017" do
      Mongar::Mongo.new.port.should == 27017
    end
  end
  
  describe "#status_collection" do
    it "should set the status_collection if an argument is passed" do
      @mongo.status_collection(:something)
      @mongo.instance_variable_get(:"@status_collection").should == :something
    end
    
    it "should return the status_collection if no argument is passed" do
      @mongo.status_collection.should == 'stati'
    end
    
    it "should default to statuses" do
      Mongar::Mongo.new.status_collection.should == 'statuses'
    end
  end
end
