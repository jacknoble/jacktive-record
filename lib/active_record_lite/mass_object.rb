class AssignmentError < StandardError
end

class MassObject < Object

  def self.my_attr_accessible(*attributes)
    self.white_list.concat(attributes)
  end

  def initialize(params = {})
    params.each_pair do |attribute, object|
      if self.class.white_list.include?(attribute.to_sym)
        self.send("#{attribute}=", object)
      else
        raise AssignmentError.new "mass assignment to unregistered attribute #{attribute}"
      end
    end
  end

  def self.my_attr_accessor(*vars)
    vars.each do |var|
      define_method("#{var}") do
        self.instance_variable_get("@#{var}".to_sym)
      end

      define_method("#{var}=") do |value|
        self.instance_variable_set("@#{var}", value)
      end

    end
  end

  def self.white_list
    @white_list ||= []
  end

# takes an array of hashes.
# returns array of objects.
  def self.parse_all(results)
    results.map{|row| self.new(row)}
  end

end
