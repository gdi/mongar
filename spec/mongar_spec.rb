require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Mongar" do
  describe "#log" do
    before do
      @mongar = Mongar.new
    end
    it "should setup a logger for the file name specified" do
      @mongar.log "/tmp/mongar_test.log"
      @mongar.logger.instance_variable_get(:@logdev).instance_variable_get(:@filename).should == "/tmp/mongar_test.log"
    end
    it "should setup a logger for standard out" do
      @mongar.log :stdout
      @mongar.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev).should be_a_kind_of(IO)
    end
  end
  
  describe "#log_level" do
    before do
      @mongar = Mongar.new
    end
    it "should set the log level on a logger created after the log_level statement" do
      @mongar.log_level :fatal
      @mongar.log :stdout
      @mongar.logger.level.should == Logger::FATAL
    end
    it "should set the log level on a logger created before the log_level statement" do
      @mongar.log :stdout
      @mongar.log_level :fatal
      @mongar.logger.level.should == Logger::FATAL
    end
  end
  
  describe "#set_log_level" do
    before do
      @mongar = Mongar.new
      @mongar.log :stdout
      @mongar.instance_variable_set(:@log_level, :info)
      @mongar.set_log_level
    end
    
    it "should set the log level on each logger" do
      @mongar.logger.level.should == Logger::INFO
    end
    
    it "should convert :info to Logger::INFO" do
      @mongar.instance_variable_set(:@log_level, :info)
      @mongar.set_log_level
      @mongar.logger.level.should == Logger::INFO
    end
    
    it "should convert :fatal to Logger::FATAL" do
      @mongar.instance_variable_set(:@log_level, :fatal)
      @mongar.set_log_level
      @mongar.logger.level.should == Logger::FATAL
    end
    
    it "should convert :error to Logger::ERROR" do
      @mongar.instance_variable_set(:@log_level, :error)
      @mongar.set_log_level
      @mongar.logger.level.should == Logger::ERROR
    end
    
    it "should convert :warn to Logger::WARN" do
      @mongar.instance_variable_set(:@log_level, :warn)
      @mongar.set_log_level
      @mongar.logger.level.should == Logger::WARN
    end
    
    it "should convert :debug to Logger::DEBUG" do
      @mongar.instance_variable_set(:@log_level, :debug)
      @mongar.set_log_level
      @mongar.logger.level.should == Logger::DEBUG
    end
  end
  
  describe "#replicate" do
    before do
      class Client
      end
      
      @logger = mock(Logger)
      Logger.stub!(:new).and_return(@logger)
      @mongar = Mongar.new
      
      @block = lambda {}
      @mock_replica = mock(Mongar::Replica)
      @mock_replica.stub!(:instance_eval)
      Mongar::Replica.stub!(:new).and_return(@mock_replica)
      
      @collection = Mongar::Mongo::Collection.new
      Mongar::Mongo::Collection.stub!(:new).and_return(@collection)
    end
    
    context "given a string" do
      it "should make a new Mongar::Replica and pass it the block" do
        @mock_replica.should_receive(:instance_eval).with(&@block)
        @mongar.replicate({ Client => 'clients' }, &@block)
      end

      it "should populate Mongar.replicas with one Replica instance for Clients" do
        @mongar.replicate({ Client => 'clients' }, &@block)
        @mongar.replicas.should == [@mock_replica]
      end
    
      it "should initialize a new replica with the source and destination objects" do
        Mongar::Replica.should_receive(:new).with(:source => Client, :destination => @collection, :mongodb_name => nil, :logger => @logger)
        @mongar.replicate({ Client => 'clients' }, &@block)
      end
    end
    
    context 'given an array of destinations' do
      before do
        @mongar.replicate({ Client => ['clients', { :someotherdb => 'clients' }]})
      end
      
      it "should create 2 replicas" do
        @mongar.replicas.length.should == 2
      end
    end
    
    context "given a hash" do
      it "should initialize a new replica" do
        Mongar::Replica.should_receive(:new).with(:source => Client, :destination => @collection, :mongodb_name => :someotherdb, :logger => @logger)
        @mongar.replicate(Client => { :someotherdb => 'clients'})
      end
    end
  end
  
  describe "#mongo" do
    before do
      @mongar = Mongar.new
      
      @block = lambda {}
      
      @mock_mongo = mock(Mongar::Mongo)
      @mock_mongo.stub!(:instance_eval)
      Mongar::Mongo.stub!(:new).and_return(@mock_mongo)
    end
    
    it "should make a new Mongar::Mongo" do
      Mongar::Mongo.should_receive(:new).with(:name => :newdb).and_return(@mock_mongo)
      @mongar.mongo :newdb, &@block
    end
    
    it "should pass the block to the new Mongo" do
      @mock_mongo.should_receive(:instance_eval).with(&@block)
      @mongar.mongo :newdb, &@block
    end
    
    it "should assign the new Mongo to the Mongar::Mongo.databases hash" do
      @mongar.mongo :newdb, &@block
      Mongar::Mongo.databases[:newdb].should == @mock_mongo
    end
  end
  
  describe "#run" do
    before do
      @mongar = Mongar.new
      @replica = Mongar::Replica.new
      @mongar.replicas = [@replica]
    end
    
    it "should call run on each replica" do
      @replica.should_receive(:run)
      @mongar.run
    end
  end
end
