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



 - what does the money go to?
 - sites that integrate with find 
 - what happends with the money
 - who owns the .find tld
 - what characters are a valid name
 - how much does it cost
 - how long do i own a lease?
 - why is my lease locked?
 - how can i sell my lease
 - other similar solutions
 - why is lease not an NFT

