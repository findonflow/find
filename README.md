# FIND - Flow Integrated Name Directory

Flow does not have any equivalent to ENS or any way to lookup a user by a name/alias/nick. 

FIND is here to solve that issue. 

In order to use FIND you create your Flow Identity/Profile and store that in your account. Then you can optionally register that with FIND for a small yearly fee. 

FIND is priced with inspiration from ENS. 5 FUSD for a name a year. If you want 4 characters it is going to cost you 100 FUSD and 3 characters 500 FUSD.

## Flow Identity

Right now an Identity in FIND is a single user.  It uses the Versus profile to represent a user.


## Plans
 - do we need a ban list here?
 - structure all transactions and scripts with propper blocks and good docs
 - more inline docs
 - github actions
  - run test
	- verify that doc is up to date
 - create webpage
 - do not expose enum status out of scripts
 - create job that will listed to event and fullfill auctions with bids that are not fullfilled. prob needs an db if I cannot use graffle.io

## Testing

 `gotestsum -f testname --watch`

