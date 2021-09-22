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


### Web
 - add edit profile with EasyEdit. Do not submit each change to profile directly. Add them up and provide a status that the profile has been changed and that you should persist the changes. 
 - add search form that will show a hit if it exists or a list of names staring with string if not hit. -> PublicLease page
 - add bid boxes to publicLease page, needs profile to be able to bid.
 - public lease should have a add friend button that will mutate profile and mark as dirty but not commit directly
 - for all transactions I want a toast on top that tells the status and a ref that blocks any other transaction while the current transaction is running. but do not block the user thread. 
 -  the plan is to deploy to vercel so adding next.js here is probably wise. 
 - eventually: an event stream page where all events comming in are listed
 - for a logged in user the event where you are outbid are particulary of iterent as it shold come up if you want to up your bid for this lease. 
 - but I guess that the blocto popup will give you that notification way before this system does.  
 - listing all ongoing auctions in a subpage
 - listing all things that are on offer in another?
 - have a featured sale box on frontpage?
 - integrate with graffle.io ( i have permission)
## Testing

 `gotestsum -f testname --watch`

