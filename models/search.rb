require "json"
class Search < Sequel::Model
  one_to_many :iterations

  # overrides array to string
  %i{flat_types districts metros}.each do |meth|
    define_method "#{meth}=" do |val|
      super(val.to_json)
      instance_variable_set(:"@#{meth}", val)
    end

    define_method meth do
      res = instance_variable_get(:"@#{meth}")
      return res if res

      raw = super()
      instance_variable_set(:"@#{meth}", JSON.parse(raw))
    end
  end
end
