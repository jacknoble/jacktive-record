require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @name = name.to_s
    @params ={:class_name => name.to_s.capitalize,
              :foreign_key => "#{name}_id",
              :primary_key => "id"
              }
    params.each_pair do |key, value|
      @params[key] = value
    end
  end

  def name
    @name
  end

  def params
    @params
  end

  def type
    (@params[:class_name])
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
  end

  def type
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    assoc = BelongsToAssocParams.new(name, params)
    class_name = assoc.params[:class_name]
    fkey = assoc.params[:foreign_key].to_sym
    self.define_method(name.to_sym) do ||
      owner = DBConnection.execute(<<-SQL, self.send(fkey))
        SELECT *
        FROM #{class_name.constantize.table_name}
        WHERE #{assoc.params[:primary_key]} = ?
      SQL
      assoc.type.constantize.new(owner[0])
    end

  end

  def has_many(name, params = {})
  end

  def has_one_through(name, assoc1, assoc2)
  end

end


