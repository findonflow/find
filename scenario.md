
## New login flow

 - user is not logged in
 - user click buy NFT button on item 1 type Foo
 - login
 - start the wizard here or before login?
 - s:getStatus
  - you do not have flow to create your profile, or you do not use dapper/blocto and do not have funds to run tx 
 - not ok, tx: createProfile
  - check if you have the funds to buy? 
 - run the buy nft button tx?


## For backend
 - all 'register' code from buy tx can be removed
 - we can have separate tx to 'fix' getStatus problems.

## For frontend
 - we cannot have an active buy button since we do not know if wallet can do this action
 - we need a wizard to login that prompts the user that we have checking his account
 - we give better feedback to user as they onboard
