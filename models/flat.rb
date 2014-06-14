class Flat < Sequel::Model
  one_to_many :flat_snapshots
  one_to_many :black_lists
end

