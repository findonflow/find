# FIND - Flow Integrated Name Directory

Flow does not have any equivalent to ENS or any way to lookup a user by a name/alias/nick. 

FIND is here to solve that issue. 

In order to use FIND you create your Flow Identity/Profile and store that in your account. Then you can optionally register that with FIND for a small yearly fee. 

FIND is priced with inspiration from ENS. 5 FUSD for a name a year. If you want 4 characters it is going to cost you 100 FUSD and 3 characters 500 FUSD.


## How does it work?
 - Clone out this repo
 - install go
 - `go mod tidy`
 - `go run tasks/demo/main.go`

This will start the flow emulator in memory and run a 'storyline' consiting of multiple scripts and transactions. Here a name will be registered, sold and then we will use the browse capabilities in find to inspect and view the different views that Artifacts support

## Flow Identity

Right now an Identity in FIND is a single user.  It uses the Versus profile to represent a user.


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

 x lease should be a FT.Receiver and delegate to profile for that. 
 x artifacts are tied to a name, royalties go to a name
 x admin should be able to register without paying fusd
  - github actions
  - run test
	- verify that doc is up to date


## Serverless functions
//lookup.find.xzy <- lookup an address

//browse.find.xyz/bjartek/artifacts/1/String -> Content/Type  text/plain    Neo Bike 1 of 3, application/json { "name" : "Neo Bike 1 of 3" } application/html


## Script to get views

- collection
 - type
 - dictionary id ->
  - name
  - imageurl
  - hash
