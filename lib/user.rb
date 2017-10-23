# Users must have a primary key, a list of addresses, and a timestamp.
# Its deposit address is set when the user is initialized to the mixer's
# default deposit address.
#
class User
  include DataMapper::Resource

  property :id, Serial
  property :created_at, DateTime, default: -> (_, _) { Time.now.utc }
  # NOTE: this deposit address *must* be owned by the Mixer
  property :deposit_address, String, default: -> (_, _) { Mixer::JOBCOIN_DEPOSIT_ADDRESS }
  property :addresses, Text
end
