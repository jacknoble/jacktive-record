require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'
require 'debugger'

class SQLObject < MassObject

  extend Searchable
  extend Associatable
  # sets the table_name
  def self.set_table_name(table_name = nil)
    if table_name.nil?
      @table_name = self.to_s.underscore.pluralize
    else
      @table_name = table_name
    end
  end

  # gets the table_name
  def self.table_name
    self.set_table_name if @table_name.nil?
    @table_name
  end

  def self.all
    parse_all(DBConnection.execute("SELECT * FROM #{self.table_name}"))
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
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
    col_string = self.instance_variables.join(", ").gsub(/@/, "")
    qmark_string = Array.new(self.instance_variables.count){"?"}.join(", ")
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
    DBConnection.execute(<<-SQL, *attribute_values )
      UPDATE #{table}
      SET #{set_line}
      WHERE
        id = #{self.id}
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
