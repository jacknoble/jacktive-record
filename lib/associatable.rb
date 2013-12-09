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
    @params ={:class_name => name.to_s.camelize,
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
    @name = name
    @params = {
      :class_name => name.to_s.singularize.camelize
      :foreign_key => "#{self_class.underscore}_id"
      :primary_key => "id"
      }
    params.each_pair do |key, value|
      @params[key] = value
    end

  end

  def type
    @params[:class_names]
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    assoc = BelongsToAssocParams.new(name, params)
    fkey = assoc.params[:foreign_key].to_sym
    self.define_method(name) do
      owner = DBConnection.execute(<<-SQL, self.send(fkey))
        SELECT 
          *
        FROM 
          #{assoc.type.constantize.table_name}
        WHERE 
          #{assoc.params[:primary_key]} = ?
      SQL
      assoc.type.constantize.new(owner[0])
    end

  end

  def has_many(name, params = {})
    assoc = HasManyAssocParams.new(name, params, self.class.to_s)
    pri_key = assoc.params[:primary_key].to_sym
    self.define_method(name) do
      owned = DBConnection.execute(<<-SQL, self.send(pry_key))
        SELECT
          *
        FROM
          #{assoc.type.constantize.table_name}
        WHERE
          #{assoc.params[:primary_key]} = ?
      SQL
      assoc.type.constantize.parse_all(owned)
    end
  end

  def has_one_through(name, assoc1, assoc2)
  end

end


