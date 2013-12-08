require 'active_record_lite'
require 'securerandom'

describe SQLObject do
  before(:all) do
    # https://tomafro.net/2010/01/tip-relative-paths-with-file-expand-path
    cats_db_file_name =
      File.expand_path(File.join(File.dirname(__FILE__), "cats.db"))
    DBConnection.open(cats_db_file_name)

    class TestCat < SQLObject
      set_table_name("cats")
      my_attr_accessible(:id, :name, :owner_id)
      my_attr_accessor(:id, :name, :owner_id)
    end

    class TestHuman < SQLObject
      set_table_name("humans")
      my_attr_accessible(:id, :fname, :lname, :house_id)
      my_attr_accessor(:id, :fname, :lname, :house_id)
    end
  end

  it "::set_table_name and ::table_name sets the name of the table for a class" do
    TestCat.table_name.should == "cats"
    TestHuman.table_name.should == "humans"
    class NewTest < SQLObject
      set_table_name "testing"
    end
    NewTest.table_name.should == "testing"
  end

  it "::all returns an array of objects" do
    cats = TestCat.all
    cats.first.should be_instance_of(TestCat)
    cats.should be_instance_of(Array)
  end

  describe "::find" do
    it "finds objects by id" do
      c = TestCat.find(1)
      expect(c).not_to be_nil
    end

    it "returns a single object" do
      cat = TestCat.find(1)
      cat.should be_instance_of(TestCat)
      cat.should_not be_nil
    end

    it "returns nil if no object is found" do
      expect(TestCat.find(9999999)).to be_nil
    end
  end

  it "#create"
  it "#update"
  it "#save"

  it "#saves saves changes to an object" do
    h = TestHuman.find(1)
    n = h.fname
    h.fname = SecureRandom.urlsafe_base64(16)
    h.save
    n.should_not == TestHuman.find(1).fname
  end
end