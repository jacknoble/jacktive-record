require 'active_record_lite'

describe "searchable" do
  before(:all) do
    cats_db_file_name =
      File.expand_path(File.join(File.dirname(__FILE__), "../test/cats.db"))
    DBConnection.open(cats_db_file_name)

    class Cat < SQLObject
      set_table_name("cats")
      my_attr_accessible(:id, :name, :owner_id)
      my_attr_accessor(:id, :name, :owner_id)
    end

    class Human < SQLObject
      set_table_name("humans")
      my_attr_accessible(:id, :fname, :lname, :house_id)
      my_attr_accessor(:id, :fname, :lname, :house_id)
    end
  end

  describe "#where" do
    it "returns correct object given a single search term" do
      cat = Cat.where(:name => "Breakfast")[0]
      cat.name.should == "Breakfast"
    end

    it "returns correct object given multiple search terms (Testing AND in WHERE clause.)" do
      human = Human.where(:fname => "Matt", :house_id => 1)[0]
      human.fname.should == "Matt"
    end
  end
end
