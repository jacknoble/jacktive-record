require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'
require 'debugger'

class SQLObject < MassObject

  extend Searchable
  extend Associatable
 
  def self.set_table_name(table_name = nil)
      @table_name = table_name
  end

  def self.table_name
    (@table_name.nil?) ? self.to_s.underscore.pluralize : @table_name
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{self.table_name}"))
  end

  def self.find(id)
    object = DBConnection.execute("SELECT * FROM #{self.table_name} WHERE id = ?", id)[0]
    (object) ? self.new(object) : nil
  end

  def attribute_values
    arr = self.instance_variables.map do |var|
      self.instance_variable_get(var)
    end
  end

  # executes query that creates record in db with objects attribute values.
  # use send and map to get instance values.
  # after, update the id attribute with the helper method from db_connection
  def create
    col_array = self.instance_variables
    col_array.delete(@id)#you don't get to assign an object's id
    qmark_string = Array.new(col_array.count){"?"}.join(", ")
    col_string =  col_array.join(", ").gsub(/@/, "")
    DBConnection.execute(<<-SQL, *attribute_values )
      INSERT INTO #{self.class.table_name}
        (#{col_string})
      VALUES (#{qmark_string})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    set_line = self.instance_variables.map do |var|
      "#{var} = ?".gsub(/@/, "")
    end
    set_line = set_line.join(", ")
    table = self.class.table_name
    DBConnection.execute(<<-SQL, *attribute_values, self.id )
      UPDATE #{table}
      SET #{set_line}
      WHERE
        id = ?
    SQL
  end

  # call either create or update depending if id is nil.
  def save
    if self.id.nil?
      self.create
    else
      self.update
    end
  end

end
