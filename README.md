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

In a separate TTY, start the mixer HTTP API:

```
bundle exec rackup config.ru
```

Finally, initialize the mixer deposit address poller:

```
bundle exec sidekiq -r ./config/sidekiq.rb
```
This kicks off a recurring job to poll the mixer's public deposit address for new deposits from registered users (note that deposits from unregistered users are simply [ignored]() for the time being).

## Register a user

The web API allows new users to 'register' via `POST /registrations`. 
