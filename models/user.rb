# Users must have a primary key, a list of addresses, and a timestamp.
#
class User
  include DataMapper::Resource

  MultipleRegisteredUsersWithSameAddress = Class.new(StandardError)
  ObjectNotFound = Class.new(StandardError)

  property :id, Serial
  property :name, String
  property :created_at, DateTime
  property :addresses, Text
  has n, :deposits

  validates_uniqueness_of :name
  validates_with_method :addresses, :is_array?
  validates_with_method :addresses, :not_used?

  def humanized_errors
    errors.flat_map { |e| e }.join
  end

  class << self
    def from_transaction_hash(hash)
      new(
        addresses:  Array(hash['fromAddress']),
        created_at: hash['timestamp']
      )
    end

    def find_by_address(address)
      found = all.select { |u| u.addresses_list.include?(address) }
      case found.size
      when 0
        nil
      when 1
        found.first
      else
        raise MultipleRegisteredUsersWithSameAddress
      end
    end

    def find_by_address!(address)
      found = all.select { |u| u.addresses_list.include?(address) }
      case found.size
      when 0
        raise ObjectNotFound
      when 1
        found.first
      else
        raise MultipleRegisteredUsersWithSameAddress
      end
    end
  end

  def addresses_list
    JSON.parse(self.addresses)
  end

  private

  def is_array?
    if addresses_list.is_a?(Array)
      true
    else
      [false, "Addresses must be a comma separated list"]
    end
  end

  def not_used?
    used = addresses_list.any? do |a|
      jobcoin_address = Jobcoin::Address.new(a)
      jobcoin_address.transactions.size > 0
    end

    if used
      [false, "One or more of the provided addresses has already been used"]
    else
      true
    end
  end
end
