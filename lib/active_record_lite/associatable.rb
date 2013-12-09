require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'
require 'debugger'

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

  def [](sym)
    @params[sym]
  end

  def type
    (@params[:class_name])
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @params = {
      :class_name => name.to_s.singularize.camelize,
      :foreign_key => "#{self_class.underscore}_id",
      :primary_key => "id"
      }
    params.each_pair do |key, value|
      @params[key] = value
    end

  end

  def [](sym)
    @params[sym]
  end

  def type
    @params[:class_name]
  end
end

module Associatable
  def assoc_params
    @assoc_params
  end

  def belongs_to(name, params = {})
    assoc = BelongsToAssocParams.new(name, params)
    @assoc_params ||= {}
    @assoc_params[name.to_sym] = assoc
    fkey = assoc_params[name][:foreign_key].to_sym
    define_method(name) do
      owner = DBConnection.execute(<<-SQL, self.send(fkey))
        SELECT
          *
        FROM
          #{assoc.type.constantize.table_name}
        WHERE
          #{self.class.assoc_params[name][:primary_key]} = ?
      SQL
      assoc.type.constantize.new(owner[0])
    end

  end

  def has_many(name, params = {})
    assoc = HasManyAssocParams.new(name, params, self.class.to_s)
    @assoc_params ||= {}
    @assoc_params[name.to_sym] = assoc
    primary_key = assoc_params[name][:primary_key].to_sym
    define_method(name) do
      owned = DBConnection.execute(<<-SQL, self.send(primary_key))
        SELECT
          *
        FROM
          #{assoc.type.constantize.table_name}
        WHERE
          #{self.class.assoc_params[name][:primary_key]} = ?
      SQL
      assoc.type.constantize.parse_all(owned)
    end
  end

  def has_one_through(name, assoc1, assoc2)
    fkey = assoc_params[assoc1][:foreign_key].to_sym

    define_method(name) do
      target_class = assoc2.to_s.camelize.constantize
      joining_class = self.class.assoc_params[assoc1][:class_name].constantize
      join_fkey = joining_class.assoc_params[assoc2][:foreign_key]
      join_pkey = joining_class.assoc_params[assoc2][:primary_key]
      pkey = self.class.assoc_params[assoc1][:primary_key]
      assoc_object =DBConnection.execute(<<-SQL, self.send(fkey))
        SELECT #{target_class.table_name}.*
        FROM #{target_class.table_name}
        JOIN #{joining_class.table_name}
        ON #{join_fkey} = #{target_class.table_name}.#{join_pkey}
        WHERE #{joining_class.table_name}.#{pkey} = ?
      SQL
      target_class.new(assoc_object[0])
    end

  end

end


