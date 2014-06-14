class BlackList < Sequel::Model
  one_to_many :users
  one_to_many :flats
end
