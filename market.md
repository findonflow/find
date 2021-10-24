# Market

Stakeholder: 
 - owner: somebody who owns a name
 - user: somebody how wants to buy/bid on a name


An owner can list a name for direct sale specifing sale price
An owner can cancel a name that is for direct sale
An user can buy a name that is for direct sale if he bids an amount that is the same as the sale price

An owner can list a name for auction specifing 
 - the amount a bid must have for an auction to start
 - the amount a bid must have for an auction to be settled. Must be larger then amount on line above(if time runst out and reserve price not met then cancel)
 - the duration of the auction
 - the extention time on a late bid

An owner can cancel an auction that is not finished


An user can add a blind bid to an name that is not in an active auction

A user can increase his bid on an auction

A user can fullfill an auction that has ended
A owner can fullfill an auction that has ended


## I had this in but we remove it
A name that is listed both for auction and for sale will sell directly if bid is above sell price 
A name that is listed both for auction and for sale will start auction if bid is belove sell price but above auction price
