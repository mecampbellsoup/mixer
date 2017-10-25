## Bitcoin Mixer

This project builds a JSON HTTP API which handles requests to interact with our primitive Jobcoin mixer.

The endpoints it exposes are:

* `POST /register -d '{ "name": "SomeUser", "addresses": ["abc1", "def2", "ghi3"] }'`

It also polls the Jobcoin blockchain for new deposits to the mixer's public deposit address via `bin/poll`.

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
bin/poll
```

This kicks off a recurring job to poll the mixer's public deposit address for new deposits from registered users (note that deposits from unregistered users are simply [ignored](https://github.com/mecampbellsoup/mixer/blob/5c57dc9ea34ed6bc893d0426aa63edf49d25f500/jobs/poll_mixer_deposit_address_job.rb#L20-L23) for the time being).

Once new user deposits are seen, they are ingested and a [schedule of obfuscation & repayment Jobcoin transactions](https://github.com/mecampbellsoup/mixer/blob/5c57dc9ea34ed6bc893d0426aa63edf49d25f500/lib/mixing_schedule.rb#L43-L47) is [enqueued](https://github.com/mecampbellsoup/mixer/blob/5c57dc9ea34ed6bc893d0426aa63edf49d25f500/models/deposit.rb#L64-L67).

## Using the mixer service

### Register a user

The web API allows new users to 'register' via `POST /registrations`. For example:

```bash
curl -XPOST localhost:9292/registrations -d '{ "name": "Alice", "addresses": ["Alice1", "Alice2", "Alice3"] }'
```
Registration is required so that the mixer knows where to send received deposits from users (i.e. knows about a user's return addresses).

In the above example, your mixed jobcoins will be returned in random chunks to `'Alice1', 'Alice2', 'Alice3'`.

**NOTE:** The mixer will *only* consider Jobcoin transactions received by the mixer's public deposit address which **come from the address 'Alice'** (the registered user's name) to be associated with this registered user.

### Give your user some jobcoins

Go [here](https://jobcoin.gemini.com/amiable) to the Jobcoin UI and enter your newly-registered user's name as the address for the new coins you're creating.

### Send your user's JBC to the mixer's public deposit address

![image](https://user-images.githubusercontent.com/2043821/32019066-f3305284-b999-11e7-832b-77367cde9f65.png)

### Sit back and relax!

Your JBC will be transferred around the mixer's addresses. You will see these transactions appear on the blockchain over the next few minutes.

Eventually all the deposited JBC will be returned to your return addresses, which you own.

## Fees

This is a zero-fee mixer :)

There are lots of ways to skin a cat, but if I were to add a fee I could adjust the implementation of `MixingSchedule#increments` to deduct a fixed (or percentage) fee from the deposited amount.

## Running the tests

```bash
rspec
```

## Discussion

### Code-related

This challenge took me 2 or 3 working days to complete.

I cut corners primarily on practicing test driven development - I felt like I needed to move quickly and just didn't have time to write as many tests as I normally would like to.

One spot that I particularly liked is the [strategy that I use to compare a Jobcoin deposit to the mixer's public address with rows in the `deposits` table](https://github.com/mecampbellsoup/mixer/blob/50dc3a50d7f5f3aa877b0cff922d5f2eb9987eff/jobs/poll_mixer_deposit_address_job.rb#L16). Specifically it uses a hashing function to make it fast 'n easy to compare the two transactions and to subsequently decide whether or not the Jobcoin deposit at hand should be ingested or not.

### Mixer security concerns

In a future version of this mixer, I would change one aspect in particular: all internal obfuscation transactions should have the same (or at least a fixed set of possibilities) amount, similar to what [CoinJoin](https://en.bitcoin.it/wiki/CoinJoin#Isn.27t_the_anonymity_set_size_limited_by_how_many_parties_you_can_get_in_a_single_transaction.3F) does.

> A coinjoin transaction is one where multiple people have agreed to form a single transaction where some of the the outputs have the same value.

![image](https://user-images.githubusercontent.com/2043821/32018910-6d62c6a0-b999-11e7-92ff-c0ae161fa1e6.png)
