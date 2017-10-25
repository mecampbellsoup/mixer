$:.unshift File.dirname(__FILE__)

task :test do
  require 'spec/spec_helper'
  system('rspec spec')
end

namespace :jobcoin do
  desc "Polls the mixer's Jobcoin deposit address for new deposits since the previous check"
  task :check_for_new_deposits do
    # need some concept of 'last seen deposit'
    client = Jobcoin::Address.new(Mixer::JOBCOIN_DEPOSIT_ADDRESS)
    all_deposits = client.transactions.select { |t| t['toAddress'] == Mixer::JOBCOIN_DEPOSIT_ADDRESS }

    # TODO: check how last implemented here
    last_recorded_deposit = Deposit.last

    if last_recorded_deposit
      all_deposits.delete_if do |t|
        # delete from the list of 'new deposits' if the transaction's timestamp
        # is not greater than the last recorded deposit's created_at timestamp.
        DateTime.parse(t['timestamp']) > last_recorded_deposit.created_at
      end
    end

    # if we find new deposits, first identify the registered user that sent it
    # if unregistered user, we do nothing (and probably just keep or send back the coins)
    all_deposits.each do |t|
      from_address = t['fromAddress']
      next unless from_address

      user = User.find_by_address!(from_address)
      deposit = Deposit.from_transaction_hash(t)
      puts "New deposit #{deposit.inspect} found belonging to user #{user.inspect}"
      user.deposits << deposit

      # does saving the user *also* save the deposit record and associate the two?
      binding.pry
      user.save
    end
  end
end

task default: %w[test]
