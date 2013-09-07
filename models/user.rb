require 'bcrypt'
class User < Sequel::Model 
  one_to_many :searches
  plugin :association_dependencies, :searches => :delete
  # users.password_hash in the database is a :string

  def password
    @password ||= BCrypt::Password.new(password_hash)
  end

  def password=(new_password)
    @password = BCrypt::Password.create(new_password)
    self.password_hash = @password
  end

end
