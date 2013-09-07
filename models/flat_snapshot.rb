class FlatSnapshot < Sequel::Model
  include Comparable
  many_to_one :iteration
  many_to_one :flat

  def before_create
    last = FlatSnapshot.last(flat_id: flat_id)
    if last.nil?
      self.changed = true
      self.unread = true
    elsif self != last
      self.changed = true
      self.unread = true
    else # self == last
      self.unread = last.unread
    end
    true
  end

  def <=>(other)
    incomparable_columns = %i{id iteration_id created_at unread changed}
    columns = FlatSnapshot.columns - incomparable_columns
    return 1 if other.nil?

    res = 0
    columns.each{ |c| res = 1 and break if self.send(c) != other.send(c) }
    res
  end

# TODO rework me

  SHORT_FORMAT_FIELDS = [:address, :description, :details,
                           :price, :stage, :stage_amount]

  def to_s(format = :short)
    methods = self.class.columns - [:id]
    if format == :short
      methods = methods.select{|m| SHORT_FORMAT_FIELDS.include? m }
    end
    methods.inject([]) do |data, m|
      data << "#{m}: #{send m}"
      data
    end.join("\n")
  end

end
