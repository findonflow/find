# Frontpage


## Box1

Find allows you to lease a name in the network so that your friends do not have to remember a 18 digit long hex string to find you.


## Box2
Find uses the versus profile to show information about you as a user. You can add an avatar, a nick and a description as well as social links

NB! Any content in the profile is your responsibility. 

## Box3

Want to get a new name?

In FIND you can bid on any name in the network! You can list your own names for direct sale or for an english auction. 

The network takes a 5% royalty on secondary market sales. 


## Technical 1
On testnet:
 - 0xFIND: 0x85f0d6217184009b
 - 0xProfile - 0x99ca04281098b33d

On Mainnet: 
 - 0xFIND - ??
 - 
```
import FIND from 0xFIND

pub fun main(name: String) :  Address? {
    return FIND.lookupAddress(name)
}
```

## Tehnical 2
If you want to lookup a profile and show it directly you can the following to get a READ only model
```
import FIND from 0xFIND
import Profile from 0xProfile
pub fun main(name: String) :  Profile.UserProfile? {
    return FIND.lookup(name)?.asProfile()
}
```

On testnet:
 - 0xFIND: 0x85f0d6217184009b
 - 0xProfile - 0x99ca04281098b33d

On Mainnet: 
 - 0xProfile - 0xd796ff17107bbff6
 - 0xFIND - ??


## FAQ


### what happends when i register a lease
FIND integrates with the profile contract from the Versus project. If you do not have a profile already it will create a new one for you that uses the name you just registered. 


###  what does the money go to?
(do we need this?)
The income from flow will go to its creator (bjartek) so that he can continue to dedicate his time to the flow ecosystem and help it thrive.

### sites that integrate with find 
Find will be integrated into the following sites at launch
 - versus.auction
 - flowscan.org

If you want to be on this list let me know

###  who owns the .find tld
The find top level domain is owned by find 

### what characters are a valid name
A valid find name is 0-9a-z, minimum 3 tokens. Also it cannot be a Flow address, so not 0x<16hex>

This is to ensure that it can be used in urls and to keep things simple.

### how much does it cost
Find is charged in the FUSD stable coin for a 365 day lease. This is done to keep prices stable and avoid a high increase if the flow token increases. 

Currently the price structuer is as follows:
 - 5+ characters: 5 FUSD
 - 4 characters: 100 FUSD
 - 3 charactesrs: 500 FUSD
 
 
### What happends when a lease expires
When a lease expires the name is locked for 90 days. 
During the lock period the owner can reactivate it but nobody else can register it. 
This is done to ensure that bots do not snatch up just freed names that some poor user has forgotten to extend the lease for.
During the lock period you can sell a lease, however note that if an aucion goes over the 90 day limit the sale will not go through.

## how long do i own a lease?
You own a name for 365 days when you pay for it. You can pay for as many years as you like.

## why is my lease locked?
Your lease is locked because it is over a year since you last paid for it. You can reactivate it. The lease will be freed for anybody else after 90 days

## how can i sell my lease
A lease in FIND is not a NFT, bauce the current NFT standard makes it impossible for the FIND network to be correct whene moving/selling leases. 

FIND has built in suport for a sophistiated market. 
 - a user can bid on any lease in what we call a blind bid
 - a owner can accept a blind bid and directly sell or use that to start an auction.
 - a owner can list a lease for direct sale, any bid at that price will sell it instantly
 - a owner cal list a leaes for auction specifying: 
   - the minimum bid to start the auction
   - the reserve price that must be met to fulfill the sale
   - the duration of the auction
 - an late bid on a auction in FIND will automatically extend the auction to 5 minutes remaining
 - a user can mamage his bids in his profile
  - a bid can be cancelled if it is a blind bid or if the bid is on a lease that is now free 
  - a bid can be increased
 - anybody both a user and a owner can fulfill an ended auction. 

## other similar solutions
While i created FIND in the spring/summer of 2021 Mynft was also developing flowns.org. I had no idea about this and they did not know abou me. 

I hope that find and flowns can coexisting as different TLD's and help each other build tools to make it possible for users of the flow blockchain to find people and things they love. 

## why is lease not an NFT
A lease in FIND is not an NFT because the current NFT spec makes it very hard to update the FIND network global state when resources change owners. 

