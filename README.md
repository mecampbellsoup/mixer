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

### Jobcoin API

* `GET /addresses/:address`
* `GET /transactions` -> list all Jobcoin transactions
* `POST /transactions` -> `fromAddress` string, `toAddress` string, `amount` string

Can send transactions via the Jobcoin API - useful for automatically sending coins back to the user after they have mixed.

### What does "mixing coins" mean in practice?

User privately submits to the mixer a list of addresses under their control.  
User sends coins to a known, public deposit address owned by the mixer.  
When they receive the coins after mixing, the transactions should be broken into random amounts and sent from new addresses.  
But how can the mixer create new addresses under its control?  
Without HD addresses (i.e. can derive new addresses from an existing keypair), I don't think there will be any "internal" transactions within the mixer. Contrast this with something like CoinJoin which is all about creating "net no change" transactions among users...  

Only users have deposits. If coins are deposited to the mixer's public deposit address, then we just keep them and do nothing (since no user will be recognized). 


### Security considerations

* Should the `POST /register` endpoint require a certain number of addresses, e.g. `N >= 3`?
* Is it insecure for the mixer's Jobcoin address to be public and static, i.e. "Mixer"? What defines ownership of the address in Jobcoin? It seems like the answer is hand-wavey... i.e. "we know it's Alice's because it's Alice, dummie". 

### user regsiters

how does the user obtain the unused Jobcoin address? that is a precondition/assumption. in other words, `GET /address` must return `[200, { transactions: [] }, { content-type: json }]` or something like that.

`validate_address_is_unspent -> GET /address/:user_submitted_address`

since it can be a list of addresses, must do it for all submitted addresses. if any are not unspent just fail the request, rollback any db transactions.

### 'user registration'

need to keep records of:

* unique user id
* the addresses that user has registered so we can do `user.addresses` when sending their coins back
* user ip address? probably not necessary atm...

### polling the mixer's address

once a user registers, we need to begin polling the mixer deposit address