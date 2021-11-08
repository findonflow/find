# FIND - Flow Integrated Name Directory

Flow does not have any equivalent to ENS or any way to lookup a user by a name/alias/nick. 

FIND is here to solve that issue. 

In order to use FIND you create your Flow Identity/Profile and store that in your account. Then you can optionally register that with FIND for a small yearly fee. 

FIND is priced with inspiration from ENS. 5 FUSD for a name a year. If you want 4 characters it is going to cost you 100 FUSD and 3 characters 500 FUSD.

## Flow Identity

Right now an Identity in FIND is a single user.  It uses the Versus profile to represent a user.


## Plans
 - github actions
  - run test
	- verify that doc is up to date

## Testing
  
 `gotestsum -f testname --watch`

## v1
 - ERROR: error handling in transaction popup
  - ask dapper about standard error messages 
 - regex name max 16 characters in frontend
 - change to flowscan
 - gui polish
 - copy
 - partnership

### Press
 - press release
 - mission statement
 - dapper
 - flowverse
 - twitter 

### Integration
 - fcl
 - versus
 - flowscan

## v2
 - notifications, feeds


## TODO

 - a royalty should have a collection of wallets -> capability it supports
 - TypeAdapter, convert one type to another. Set in artifact contract. 
 - a lease should be a FT.Receiver and delegate to profile for that. 
 - a Forge can be bought from a lease
 - FIND needs a collection of addons -> price
 - a lease can buy addons
 - mark in lease if they have addons or not
 - artifacts are tied to a name, royalties go to a name
 - make forge usable from lease collection
 - unlock forge 50 usd
 - admin should be able to register without paying fusd
