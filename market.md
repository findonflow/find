# Market

Stakeholder: 
 - owner: somebody who owns a name
 - user: somebody who wants to buy/bid on a name


An owner can list a name for direct sale specifying sale price
An owner can cancel a name that is for direct sale
A user can buy a name that is for direct sale if he bids an amount that is the same as the sale price

An owner can list a name for auction specifying 
 - the amount a bid must have for an auction to start
 - the amount a bid must have for an auction to be settled. Must be larger than amount on line above(if time runst out and reserve price not met then cancel)
 - the duration of the auction
 - the extension time on a late bid

An owner can cancel an auction that is not finished

A user can add a blind bid to a name that is not in an active auction
A user can increase his bid on an auction



## I had this in but we remove it
A name that is listed both for auction and for sale will sell directly if bid is above sell price 
A name that is listed both for auction and for sale will start auction if bid is below sell price but above auction price


# DoneDeal

We chose to not expose to any user, only winning bidder and owner
A user can fulfill an auction that has ended
An owner can fulfill an auction that has ended


## Bugs
 - if you have a profile the final bid line should be a link to your profile with your name
 - when you run fillfull if the owner does not have a profile create the profile with the same name they just bought
 - name_status should not fail if you don't have a profile
