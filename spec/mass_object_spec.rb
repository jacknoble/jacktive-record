require 'active_record_lite'

# Use these if you like.
describe MassObject do
  describe "::my_attr_accessor" do
    subject(:obj) { MyMassObject.new }

    before(:each) do
      class MyMassObject < MassObject
        my_attr_accessor(:x, :y)
      end
    end

    it "adds getter and setter methods" do
      obj.methods.should include(:x)
      obj.methods.should include(:y)
      obj.methods.should include(:x=)
      obj.methods.should include(:y=)
    end

    it "adds getter and setter methods to each subclass separately." do
      class AnotherObject < MassObject
        my_attr_accessor :a
      end

      obj2 = AnotherObject.new

      obj2.methods.should_not include(:x)
      obj2.methods.should include(:a)
      obj2.methods.should_not == obj.methods
    end
  end

  describe "::my_attr_accessible" do
    before(:each) do
      class MyMassObject < MassObject
        my_attr_accessible(:x, :y)
      end
    end

    it "::white_list should return array of whitelisted attributes." do
      MyMassObject.white_list.sort.should == [:x, :y]
    end

    it "should raise an error when mass assigning non-whitelisted attribute" do
      expect do
        MyMassObject.new({ :not_protected => "WATTTT!" })
      end.to raise_error("mass assignment to unregistered attribute not_protected")
    end

    it "should not raise an error when mass assigning whitelisted attributes" do
      expect do
        MyMassObject.new({ :x => "a", :y => "b" })
      end.to_not raise_error
    end

    it "should update instance variable values" do
      class AnotherMyMassObj < MassObject
        my_attr_accessible(:x, :y)
        my_attr_accessor(:x, :y)
      end
      obj = AnotherMyMassObj.new({ :x => "a", :y => "b" })
      obj.x.should == "a"
      obj.y.should == "b"
    end
  end

  describe "::parse_all" do
    it "takes an array of hashes and returns objects" do
      objs = MyMassObject.parse_all([{:x => :x1_val, :y => :y1_val},
                                    {:x => :x2_val, :y => :y2_val}])
      objs.first.should be_an_instance_of(MyMassObject)
    end
  end

  describe "#initialize" do
    subject(:obj) { MyMassObject.new(:x => :x_val, :y => :y_val)  }

    before(:each) do
      class MyMassObject < MassObject
        my_attr_accessor(:x, :y)
        my_attr_accessible(:x, :y)
      end
    end

    it "accept a hash of attribute names and values, assigning the values to instance variables" do
      obj.x.should == :x_val
      obj.y.should == :y_val
    end

    it "also accepts a hash with strings as keys" do
      mass_object = MyMassObject.new("x" => :x_val, "y" => :y_val)
      mass_object.x.should == :x_val
      mass_object.y.should == :y_val
    end

    it "raises an error when attributes are attempted to be mass assigned to attributes not in the whitelist" do
      expect { MyMassObject.new(:a => :testing) }.to raise_error
    end
  end
end
