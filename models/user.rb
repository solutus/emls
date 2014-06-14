require 'bcrypt'
class User < Sequel::Model
  one_to_many :searches
  one_to_many :black_lists
  plugin :association_dependencies, :searches => :delete

  def password
    @password ||= BCrypt::Password.new(password_hash)
  end

  def password=(new_password)
    @password = BCrypt::Password.create(new_password)
    self.password_hash = @password
  end

  def search(search_id)
    searches_dataset[search_id]
  end

  def iterations(search_id)
    @iterations = search(search_id).iterations
  end

  def iteration(iteration_id)
    Iteration.where(id: iteration_id,
                    search_id: searches_dataset.select(:id)).first
  end

  def flat_snapshots(iteration_id)
    black_sort iteration(iteration_id).flat_snapshots
  end

  def last_flat_snapshots(search_id)
    black_sort search(search_id).last_flat_snapshots
  end

  private
  def black_sort(flat_snapshots)
    flat_snapshots.sort_by{|fs| fs.black? ? 1 : 0 } # black in the end
  end
end
