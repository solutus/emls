class Flat < Sequel::Model
  one_to_many :flat_snapshots
end
