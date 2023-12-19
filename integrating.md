# How to integrate with .find

We advice anybody that is integrating to contact us in [discord in the technical channel](https://discord.gg/8a27XMx8Zp) 


## Resolving names <> addresses
In order to integrate with .find you have a couple of options. 

 - use flow-cadut with the [.find plugin](https://codesandbox.io/s/lqcw0). Shout out to the amazing [MaxStarka](https://github.com/maxstalker) for this
 - integrate using cadence scripts 
 - use the web2 serverless api
 
 
### The web2 serverless api

This api is access(all)lished at  https://lookup.find.xyz/api/lookup

It can be called either with a name or an address

- https://lookup.find.xyz/api/lookup?name=bjartek -> will resolve to my address
- https://lookup.find.xyz/api/lookup?address=0x886f3aeaf848c535-> will resolve to my primary name 


### Using Cadence directly

The contract addreses for .find is:
 - mainnet: 0x097bafa4e0b48eef
 - testnet: 0x35717efbbce11c74


We have tried to make it easy to use .find in cadence so most functions are oneliners. 

```cadence
import FIND from 0x097bafa4e0b48eef

access(all) main(name: String) : Address?  {
  return FIND.lookupAddress(name)
}
```

If you want the read-only profile of a user for displaying in your solution you can use the `lookup` function
```cadence
import FIND, Profile from 0x097bafa4e0b48eef

access(all) main(name: String) :  Profile.UserProfile? {
    return FIND.lookup(name)?.asProfile()
}
```

## Resolving address -> name

```cadence
import FIND, Profile from 0x097bafa4e0b48eef

access(all) main(address: Address) :  String? {
    return FIND.reverseLookup(address)
}
```

## Using the Profile in your solution

If you want to create Profiles in .find in your solution that is possible. 

Contract us in discord if you want this so that we can discuss it further:


Please do not use any of these raw but as inspiration :)

 - [createProfile](transactions/createProfile.cdc) : create a profile with just a name. NB! this hard codes the  'createdAt' on line 22 to .find 
 - [setPFP](transactions/setProfile) : sets the PFP profile picture
 - [editProfile](transactions/editProfile) : edit the profile
 - [getProfile from address](scripts/profile.cdc) : to get from name, if you have .find name ise lookup as explained above
 
## Show your NFT in .find

We support all NFTs that are on [NFT-Catalog](https://nft-catalog.vercel.app/catalog/mainnet) which is proposed and maintained by Dapper Team. 

To register on NFT Catalog, please follow the [instructions](https://nft-catalog.vercel.app/v) provided by Dapper. 

Implementing MetadataViews standards in the right way can help your NFTs display with a richer metadata. The doc to MetadataViews standard is linked [here](./integratingMetadataViews.md). 


<!-- In order to show your nfts in .find we use this [script](scripts/collections.cdc)

In essence what we need for each nft is the fields:
```
	access(all) let id:UInt64
	access(all) let name: String: The name of the nft
	access(all) let image: String : the http url to the image, or ipfs://<cid>
	access(all) let url: String: the url to go to when an nft is clicked
	access(all) let listPrice: UFix64? : if this is item is listed in a marketplace show the price here
	access(all) let listToken: String? : the string representation of the token used. Identifier of FT
	access(all) let contentType:String : content type of image url, image or video works fine here
	access(all) let rarity:String: rarity description for this NFT
``` -->

<!-- There are lots of examples for how this is done in the collections script already. 

Note that if your solution needs to lookup things in an API after the collections script we can accomodate that aswell. -->

## Login using your .find name

We have a demo of using a .find name to log in with here from a community member. Expect more to come here later

https://github.com/lightbeardao/find-auth-example

## Verifying .find name in discord

Using the [Emerald bot](https://github.com/jacob-tucker/blocto-auth-discord-bot) it is possible to give users that have a valid .find name a role in your discord. 

1. invite Emerald#5944 into your discord
2. Create a new role that is below the Emerald role in your discord
3. as admin of discord run `!setup FIND <your role>`
4. This will give that channel an `Validate` button you can press that pops up a web page that logs you in to your account and verifies if you own atleast one active .find name
 

