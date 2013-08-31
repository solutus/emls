class Iteration < Sequel::Model
  many_to_one :search
  one_to_many :flats
  def before_create
    self.created_at = Time.now
    super
  end
end
