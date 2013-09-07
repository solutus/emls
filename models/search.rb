require "json"
class Search < Sequel::Model
  many_to_one :user
  one_to_many :iterations
  plugin :association_dependencies, :iterations => :delete

  # overrides array to string
  %i{flat_types districts metros}.each do |meth|
    define_method "#{meth}=" do |val|
      val = [val].flatten.map(&:to_i) # wrap into array
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

  %i{min_price max_price min_square max_square interval}.each do |meth|
    define_method("#{meth}"){ super().to_i }
  end

  def last_flat_snapshots
    i = iterations.last
    i ? i.flat_snapshots : []
  end

  def district_names
    names Emls::DISTRICTS, districts
  end

  def metro_names
    names Emls::METROS, metros
  end

  def interval_name
    Emls::INTERVALS.invert[interval]
  end

  def flat_type_names 
    names Emls::FLAT_TYPES, flat_types
  end

  def as_json 
    columns = Search.columns - [:id]
    columns.inject({}){|hash, col| hash[col] = send(col); hash}
  end

  def run 
    Emls.new(as_json).save
  end

  private
  def names(set, subset)
    names = set.invert
    names.select{|id, name| subset.include? id}.values.join(", ")
  end
end
