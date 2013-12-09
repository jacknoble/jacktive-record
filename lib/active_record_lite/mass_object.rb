class AssignmentError < StandardError
end

class MassObject < Object

  def self.my_attr_accessible(*attributes)
    @white_list ||= []
    @white_list += attributes
  end

  def initialize(params = {})
    params.each_pair do |attribute, object|
      white_attributes = self.class.white_list
      if white_attributes.include?(attribute) || white_attributes.include?(attribute.to_sym)
        var_in_namespace = "@#{attribute.to_s}".to_sym
        self.instance_variable_set(var_in_namespace, object)
      else
        raise AssignmentError.new "mass assignment to unregistered attribute #{attribute}"
      end
    end

  end

  def self.my_attr_accessor(*vars)
    vars.each do |var|
      varname = var.to_s

      define_method("#{varname}") do
        self.instance_variable_get("@#{varname}".to_sym)
      end

      define_method("#{varname}=") do |value|
        self.instance_variable_set("@#{varname}", value)
      end

    end
  end

  def self.white_list
    @white_list
  end

# takes an array of hashes.
# returns array of objects.
  def self.parse_all(results)
    results.map{|row| self.new(row)}
  end

end
