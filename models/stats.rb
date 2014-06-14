class Stats
  def initialize(metro, max_price)
    @metro, @max_price = metro, max_price
  end

  def flats
    @flats ||= begin
      day_ago = Time.now - (60*60*24)
      flat_ids = FlatSnapshot
        .where(metro: @metro)
        .where("created_at > ?", day_ago)
        .where("price <= ?", @max_price)
        .where("stage > 1").distinct(:flat_id).map(&:flat_id)
      Flat.where(id: flat_ids).all
    end
  end

  def flat_snapshots
    @flat_snapshots ||= flats.map(&:flat_snapshots).map(&:last)
  end

  def prices
    @prices ||= Distribution.new flat_snapshots.map(&:price).map(&:to_i), 100
  end


  def prices_per_meter
    @prices_per_meter ||= Distribution.new flat_snapshots.map(&:price_per_meter).map(&:to_i), 1
  end 

  def history
    flats.each do |f|
      fss = f.flat_snapshots
      f = fss.first
      l = fss.last
      d = (l.price.to_i - f.price.to_i)
      sign = d>0 ? "\u25b2" : (d==0 ? "-" : "\u25bc")
      first_price = f.price
      last_price = l.price
      puts "#{sign} #{first_price} #{last_price} #{l.address} #{l.details} #{l.description} #{l.id}\n\n"
    end.size
  end

  class Distribution 
    def initialize(arr, mod)
      @arr = arr
      @mod = mod
    end

    def distribution
      @arr.inject({}) do |res, price|
        key = price.divmod(@mod).first
        res[key] ||= []
        res[key] << price ;res
      end.sort_by{|(k,v)| k}.each{|(average, array)| puts "#{average}: #{array}"}.size
    end
  
    def average
      @arr.reduce(:+) / @arr.size
    end
  end
end

