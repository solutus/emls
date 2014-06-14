class Iteration < Sequel::Model
  extend Forwardable
  many_to_one :search
  one_to_many :flats
  one_to_many :flat_snapshots
  plugin :association_dependencies, :flat_snapshots => :delete
  delegate :user => :search

  def before_create
    self.created_at = Time.now
    super
  end
end
