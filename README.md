## Bitcoin Mixer

This project builds a JSON HTTP API which handles requests to interact with our primitive Jobcoin mixer.

The endpoints it exposes are:

* `POST /register -d '{ addresses: ['abc1', 'def2', 'ghi3'] }'`

### How the mixer works

1. User provides a list of new, unused Jobcoin addresses that he owns via `POST /register`
2. Mixer API responds with a deposit address that it (where "it" refers to the Mixer API service) owns.
3. User transfers Jobcoins to the deposit addressed returned in the `POST /register` response body.
4. The mixer service independently polls/watches its owned addresses to watch for new user deposits to the mixer. (Implement this as a rake task.)
5. Upon detecting new deposits, the mixer transfers the deposited jobcoins from the deposit address into a "house account" with all other users' jobcoins combined therein.
6. Over time, the mixer doles out the user's deposited jobcoins in sequenece to the list of addresses originally provided by the user.
7. A fee of 2% of the total amount of jobcoins mixed is deducted from the *final* payment back to the user.

## Building & running the mixer

```
git clone https://github.com/mecampbellsoup/mixer.git
cd mixer
bundle install
```

In a separate TTY, start the mixer HTTP API if you need to register with the mixer (more on that below):

```
bundle exec rackup config.ru
```

Finally, initialize the mixer's deposit address poller:

```
bundle exec sidekiq -r ./config/sidekiq.rb
```

This kicks off a recurring job to poll the mixer's public deposit address for new deposits from registered users (note that deposits from unregistered users are simply [ignored](https://github.com/mecampbellsoup/mixer/blob/5c57dc9ea34ed6bc893d0426aa63edf49d25f500/jobs/poll_mixer_deposit_address_job.rb#L20-L23) for the time being).

Once new user deposits are seen, they are ingested and a [schedule of obfuscation & repayment Jobcoin transactions](https://github.com/mecampbellsoup/mixer/blob/5c57dc9ea34ed6bc893d0426aa63edf49d25f500/lib/mixing_schedule.rb#L43-L47) is [enqueued](https://github.com/mecampbellsoup/mixer/blob/5c57dc9ea34ed6bc893d0426aa63edf49d25f500/models/deposit.rb#L64-L67).

## Register a user

The web API allows new users to 'register' via `POST /registrations`. For example:

```bash
curl -XPOST localhost:9292/registrations -d '{ "name": "Alice", "addresses": ["Alice", "Alice1", "Alice2", "Alice3"] }'
```
**NOTE:** The mixer will *only* consider Jobcoin transactions received by the mixer's public deposit address which **come from the address 'Alice'** (the registered user's name) to be associated with this registered user.

## Fees

This is a zero-fee mixer :)

There are lots of ways to skin a cat, but if I were to add a fee I could adjust the implementation of `MixingSchedule#increments` to deduct a fixed (or percentage) fee from the deposited amount.

## Running the tests

```bash
rspec
```
