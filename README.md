## Bitcoin Mixer

This project builds a JSON HTTP API which handles requests to interact with our primitive Jobcoin mixer.

The endpoints is exposes are:

* `POST /register -d '{ addresses: ['abc1', 'def2', 'ghi3'] }'`

### How the mixer works

1. User provides a list of new, unused Jobcoin addresses that he owns via `POST /register`
2. Mixer API responds with a deposit address that it (where "it" refers to the Mixer API service) owns.
3. User transfers Jobcoins to the deposit addressed returned in the `POST /register` response body.
4. The mixer service independently polls/watches its owned addresses to watch for new user deposits to the mixer. (Implement this as a rake task.)
5. Upon detecting new deposits, the mixer transfers the deposited jobcoins from the deposit address into a "house account" with all other users' jobcoins combined therein.
6. Over time, the mixer doles out the user's deposited jobcoins in sequenece to the list of addresses originally provided by the user.
7. A fee of 2% of the total amount of jobcoins mixed is deducted from the *final* payment back to the user.

### Security considerations

* Should the `POST /register` endpoint require a certain number of addresses, e.g. `N >= 3`?