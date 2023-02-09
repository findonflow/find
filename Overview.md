# .find

.find is a solution that aims to make it easier to .find people and their things on the flow blockchain. It is live on mainnet since Dec 13th 2021 at https://find.xyz


# Product.find

 - Name Services
 - Assets Browser
 - Marketplace
 - Launchpad
 - Find Thoughts

Find out more by surfing find.xyz

# Infrastructures.find
 - Name services
 - Asset Management
 - Marketplace
 - NFT Forger
 - NFT Pack
 - Community Tools Wrapper
 - Social Networking Tools
 - User Profile
 - Related Accounts


# Name services Contracts

[FIND](./contracts/FIND.cdc) contract is the heart of the FIND name service.
It defines a name lease (which is not implementing NFT standard therefore it is not an NFT), and the usage around it.

A Lease is a permission to own and use the domain name within a period of time (in .find's case that would be an year since register in general.) Lease owner can link themselves and their wallet address with ${name}.find. Smart contracts that implement FIND can resolve the lease owner address and tell who that is without sending in the clumsy and unreadable length wallet address.

## Lease Attribute
Leases are created and handled as resource on flow. So that they are properly handled and stored.

Attributes :
name - name of the lease
networkCap - link to the network (In find we support multiple tenant, so lease can be connected to different network at creation, creating name services for different tenant)
market information - sale / auction / offer prices and details
addons - .find leases can support add ons to the name itself.

## Contract Functions

```cadence
	// resolve takes a string address or a find name and returns an address if valid
	pub fun resolve(_ input:String) : Address?

	// lookupAddress look up the address of a find name, and return the owner if there is one (and if the lease is still valid / active)
	pub fun lookupAddress(_ name:String): Address?

	// lookup looks up the find name owner's profile public interface if there is one
	pub fun lookup(_ input:String): &{Profile.Public}?

	// reverse lookup looks up the address for the user's find name
	// If they have set a find name, then return the find name
	// If they haven't set a find name, return the first name that comes up in the array
	pub fun reverseLookup(_ address:Address): String?

	// status returns the status of a find name
	// For find lease we have 3 states
	// pub case FREE - It is not owned and free to take
	// pub case TAKEN - It is already taken and in use by someone
	// pub case LOCKED - The lease is expired now, but the lease will be locked only to the previous owner who has 3-month-time to renew it
	//
	pub fun status(_ name: String): NameStatus

	// depositWithTagAndMessage sends fund from sender to user with / without profile and emit very good events
	// for users with profile, it supports as much FT as they've set up wallets in profile
	// for users without profile, we support flow and FUSD at the moment but it can be extended pretty easily
	pub fun depositWithTagAndMessage(to:String, message:String, tag: String, vault: @FungibleToken.Vault, from: &Sender.Token)
```

## Interaction Templates

Some example scripts to show how easy it is to implement FIND
- get the owner from an address or find name
```cadence
import FIND

pub fun main(input: String) : Address? {
	return FIND.resolve(input)
}
```

- get the name of an account
```cadence
pub fun main(input: Address) : String? {
	return FIND.reverseLookup(input)
}
```

# Asset Management

With [Profile](./contracts/Profile.cdc) contract, [FindUserStatus](./contracts/FindUserStatus.cdc) contract and a list of scripts, viewing and managing FT and NFT assets made possible on .find and it is convenient with a call of the script. Even more we provide User information on community products like NFT Storefront listings, flowty rental / borrows and Flovatar marketplace listings.

## Identity
Identity and Personalized descriptions are important assets and features to .find and users. They show how a User want themselves to look like on chain and identify who they are besides the lengthy address.

The information is stored under Profile resource in [Profile](./contracts/Profile.cdc) contract.

## FungibleToken
FungibleTokens are exposed under Find Profile contracts.
As soon as a user adds his/her wallet to Profile, it can be viewable in Profile report. By default we always add FUSD / USDC / Flow token for non-Dapper Users if they initiate their account on .find page.

We have a primary social tools which users can follow / unfollow / setPrivate or ban other users.

## NonFungibleToken
We fetch users NonFungibleTokens(NFT) by looking up registered collections on NFTCatalog. NFTCatalog is a collection book of NFTs created by the flow team and tells where a collection should be in the user storage. By iterating through the catalog, we can tell if user has that collection and fetch information from it.

It is a little more complicated to handle NFT information because it can come in all sorts of format. But we have some scripts ready to help you on this.

## Contract Functions

```cadence

	// Identity and FT can be fetched from below functions
	pub contract Profile {
		pub resource interface Public {
			// asReport is exposed in Public interface which Profile resource implement.
			// It can be called by getting Profile Public capability

			// asReport returns all User Profile information including
			// address, profile name, find name, description, tags etc.
			// and wallet information
			pub fun asReport() : UserReport

			// Primary social graphing functions are also exposed under the interface
			pub fun isBanned(_ val: Address): Bool
			pub fun isPrivateModeEnabled() : Bool
			pub fun getFollowers(): [FriendStatus]
			pub fun getFollowing(): [FriendStatus]
			pub fun getLinks() : [Link]
		}
	}
```

NFTs can be fetched from these scripts

- NFT script to fetch user collection with only IDs
[getNFTCatalogIDs](./scripts/getNFTCatalogIDs.cdc)

```cadence
// User : String address or find name
// collections : target collection or empty if no specific collection wanted

// @return a map of collection to ids
pub fun main(user: String, collections: [String]) : {String : ItemReport}
```

- NFT script to fetch user collection with only IDs
[getNFTDetailsNFTCatalog](./scripts/getNFTDetailsNFTCatalog.cdc)

```cadence
// User : String address or find name
// project : target collection, the key of returned map from [getNFTCatalogIDs]
// id : id of the NFT
// views : any EXTRA views wanted to resolve
/*
	Default views :
	Type<MetadataViews.Display>() ,
	Type<MetadataViews.Editions>() ,
	Type<MetadataViews.Serial>() ,
	Type<MetadataViews.Medias>() ,
	Type<MetadataViews.License>() ,
	Type<MetadataViews.ExternalURL>() ,
	Type<MetadataViews.NFTCollectionDisplay>() ,
	Type<MetadataViews.Traits>() ,
	Type<MetadataViews.Rarity>() ,
	Type<FindViews.SoulBound>()
*/

// @return a struct of NFT details :
/*
	NFT detail with MetadataViews
	Find Market Listings
	Find Market Doable actions
	Community Listings (Flovatar market, Flowty rental and borrow market, StoreFront market)
*/
pub fun main(user: String, project:String, id: UInt64, views: [String]) : NFTDetailReport?
```

# Marketplace

The .find marketplace doesn't use StoreFront because we started on this before NFTStorefront is there. .find marketplace supports more than just direct sales but also Offers, Auctions and non-Escrowed Auctions (no funds locked for auctions)

## Market Options

.find now supports below market options.
The configuration enables us to add as many more as we want on top

- Direct Sale
- Escrowed English Auction
- non-Escrowed English Auction
- Escrowed Direct Offer
- non-Escrowed Direct Offer

## Contract Structure

.find adopts the tenant structure where each address can host their own marketplace on find market contract. They can configure their own selling rules (enabled listing / FT / NFT options), cuts, etc.

```cadence
	// FindMarket defines all market related functinos and the tenant model
	pub contract FindMarket {

		// Tenant resource will be stored in FIND's main account storage.
		// It defines all the market rules / cut a tenant want.
		// Every tenant will have their unique tenant and they will not interfere each other
		pub resource Tenant {
			// in the tenant reference, call getStoragePath or getPublicPath by sending in the Market Option SaleItemCollection Type, will give you the path to SaleItemCollection
			// Example will demonstrate how to get the target saleItemCollection form a tenant name / address
			pub fun getStoragePath(_ type: Type) : StoragePath
			pub fun getPublicPath(_ type: Type) : PublicPath
		}

		// TenantClient resource will be stored in tenant account storage.
		// The capability access model is adopted so only accounts that get access to TenantClient resource with VALID tenant capability can operate and connect to dedicated tenant resource

		// i.e. if .find (as an Admin) set you up as the tenant admin to a particular tenant resource, only then the tenant can do admin operations
		pub resource TenantClient {
			access(self) var capability: Capability<&Tenant>?
		}

		// getTenantAddress can get tenant address from a tenant name
		// Please be reminded that this name IS NOT the find name and can be anything, .find team has exclusive control over tenant creation and therefore it will not be a problem
		// currently "find" will be the tenant name for find tenant or you can also call the beflow function to get "find" marketplace address
		pub fun getTenantAddress(_ name: String) : Address?

		pub fun getFindTenantAddress() : Address


		// public function to get tenant referece with public interface
		// the tenant reference and address are vital to do market operations on that particular tenant
		pub fun getTenant(_ tenant: Address) : &FindMarket.Tenant{FindMarket.TenantPublic}
	}

```

To do operations with our contract market, we have to interact directly with the implementing contract. Below would be the elaboration of Sale contract as an example and how to interact with it.

All our listings use NFT resource uuid as the unique identifier so it would be unique to each NFT and there wouldn't be duplicated listings for the same NFT in a user's listing collection

```cadence
pub contract FindMarketSale {

	// SaleItems are declared in each of the market option contracts and they store all needed information of the listing to 1 particular NFT
	pub resource SaleItem : FindMarket.SaleItem {
		// buyer of the direct sale
		access(self) var buyer: Address?
		// vault type of the listing
		access(contract) let vaultType: Type
		// pointer to the listng. If the object is moved, the pointer and thus the listing is not valid anymore
		access(contract) var pointer: FindViews.AuthNFTPointer
		// sale price
		access(contract) var salePrice: UFix64
		// listing valid in unix TimeStamp, if it is nil, it will always be valid
		access(contract) var validUntil: UFix64?
		// This is just an extrafield we set for extendability.
		// cadence is not friendly for adding new fields in contract update
		access(contract) let saleItemExtraField: {String : AnyStruct}
		// This is the total royalties of the NFT at listing creation.
		// We assert that the royalty at list and at sale are the same so that no one can game the system by manipulating royalties
		access(contract) let totalRoyalties: UFix64
	}

	// This is a public interface that expose needed information and required function to execute market interaction.
	pub resource interface SaleItemCollectionPublic {
		// fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		// borrow specific saleItem so as to get detail listing info
		pub fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem}
		// containsId is a gas efficient way to check if a listing is there. Other than getting all ids and check contains
		pub fun containsId(_ id: UInt64): Bool
		// buy function is exposed here so people can access the seller's saleItemCollection and buy the item.
		pub fun buy(id: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>)
	}

	// SaleItemCollection is similar to Collection to NFTs, it is a collection of all user's saleItmem in that market option type.
	pub resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic {
		// list for sale takes an AuthPointer, vaultType, price and valid timeStamp

		// AuthPointer is declared in FindViews.
		// It requires user to setup a provider private capability and store it in the AuthPointer struct.
		// The AuthPointer struct secures it and ensure it will only be used to withdraw the dedicated NFT

		pub fun listForSale(pointer: FindViews.AuthNFTPointer, vaultType: Type, directSellPrice:UFix64, validUntil: UFix64?, extraField: {String:AnyStruct})

		// delist takes the listing id (NFT uuid)
		pub fun delist(_ id: UInt64)

		// relist is a helper function to revalidate the listing.
		// It only takes the listing id and will try to relist for you.
		// Cases that this would be useful and handy would be :
		// 1. royalty of the NFT changed
		// 2. listing expires and would like to relist
		pub fun relist(_ id: UInt64)

	}

	// contract level function
	// getSaleItemCapability takes the marketplace (tenant) address and the user address, and return the saleItemCapability for fetching information and call buy function
	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>?
}
```

## Interaction Templates

Here we demostrate a simple interaction on
[listNFTForSale](transactions/listNFTForSale.cdc)

More detailed version with NFTCatalog and FTRegistry please refer to [listNFTForSale](transactions/listNFTForSale.cdc)

```cadence
import FindMarket
import FindMarketSale
import NonFungibleToken
import MetadataViews
import FindViews
import FlowToken

// marketplace : tenant address
// id : listing ID (not uuid) of the NFT
// directSellPrice : price
transaction(marketplace:Address, id: UInt64, directSellPrice:UFix64) {

	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer

	prepare(account: AuthAccount) {

		// Get tenant from marketplace address
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()

		let tenant = tenantCapability.borrow()!

		// get saleItemCollection from tenant specific storage path and saleItemType (in this case FindMarketSale)
		self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))

		// getProvider private capability of the selling NFT
		var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(${NFT_Provider_Private_Path})

		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		self.vaultType= Type<@FlowToken.Vault>()
	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		// access the seller's sale Item and list it for sale
		self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: nil, extraField: {})
	}
}

```

A simple demonstration on buying items

More detailed version please refer to [buyNFTForSale](transactions/buyNFTForSale.cdc)

```cadence

import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(marketplace:Address, user: String, id: UInt64, amount: UFix64) {

	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault

	let saleItemsCap: Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>

	prepare(account: AuthAccount) {

		// resolve user address here (it supports string address and find names)
		let resolveAddress = FIND.resolve(user)
		if resolveAddress == nil {
			panic("The address input is not a valid name nor address. Input : ".concat(user))
		}
		let address = resolveAddress!

		// getting SELLER's saleItemCapability so that we can call buy function from it
		self.saleItemsCap= FindMarketSale.getSaleItemCapability(marketplace: marketplace, user:address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())

		// we get the saleItem with assertOperationValid
		// It checks if the item / market currently enables market operation of this NFT type and if the buyer / seller is banned.
		// We need item here to assert on the FT type, amount as well as NFT information such as storage path.
		let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)

		// get NFT Storage path from item
		let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: item.getItemType().identifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(item.getItemType().identifier))
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
		let nft = collection.collectionData
		self.targetCapability= account.getCapability<&{NonFungibleToken.Receiver}>(nft.publicPath)

		// get FT information from item
		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
	}

	pre {
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		// call buy function in SELLER's saleItemCollection reference and deposit to BUYER's collection by sending in the receiver capability
		self.saleItemsCap.borrow()!.buy(id:id, vault: <- vault, nftCap: self.targetCapability)
	}
}


```


More Interaction templates can be found in the repo.

### FindMarketSale
[list](transactions/listNFTForSale.cdc)

```cadence
transaction(
	marketplace:Address,
	nftAliasOrIdentifier: String,
	// This is the ID of the NFT (NOT UUID)
	id: UInt64,
	ftAliasOrIdentifier: String,
	directSellPrice:UFix64,
	validUntil: UFix64?
	)

```

[buy](transactions/buyNFTForSale.cdc)
```cadence
transaction(
	marketplace:Address,
	user: String,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64,
	amount: UFix64
	)

```

[delist](transactions/delistNFTSale.cdc)
```cadence
transaction(
	marketplace:Address,
	// This is the UUID of the NFT
	ids: [UInt64]
	)

```

### FindMarketAuction (Escrowed And Soft)

[listAuctionEscrowed](transactions/listNFTForAuctionSoft.cdc)

[listAuctionSoft](transactions/listNFTForAuctionSoft.cdc)

```cadence
transaction(
	marketplace:Address,
	nftAliasOrIdentifier:String,
	// This is the ID of the NFT (NOT UUID)
	id: UInt64,
	ftAliasOrIdentifier:String,
	price:UFix64,
	// If the auction does not hit reservce price, the auction will mark as fail and cannot be completed
	// It can be the same as the auction price
	auctionReservePrice: UFix64,
	// How long the auction should last from start
	auctionDuration: UFix64,
	// How long each bid should elong the auction (if the time left is falling shorter than the extension duration)
	auctionExtensionOnLateBid: UFix64,
	// minimum increment for each bid
	minimumBidIncrement: UFix64,
	auctionValidUntil: UFix64?
	)


```

[bidMarketAuctionEscrowed](transactions/bidMarketAuctionEscrowed.cdc)

[bidMarketAuctionSoft](transactions/bidMarketAuctionSoft.cdc)

```cadence
transaction(
	marketplace:Address,
	user: String,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64,
	amount: UFix64
	)

```

[fulfillMarketAuctionEscrowed](transactions/fulfillMarketAuctionEscrowed.cdc)

```cadence
transaction(
	marketplace:Address,
	owner: String,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64
	)
```

Soft Auction works differently here because we do not escrow fund. Therefore bidder has to pass in the amount here to fulfill the auction

[fulfillMarketAuctionSoft](transactions/fulfillMarketAuctionSoft.cdc)

```cadence
transaction(
	marketplace:Address,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64,
	// amount of the completed auction to fulfill
	amount:UFix64
	)

```

[cancelMarketAuctionEscrowed](transactions/cancelMarketAuctionEscrowed.cdc)

[cancelMarketAuctionSoft](transactions/cancelMarketAuctionSoft.cdc)
```cadence
transaction(
	marketplace:Address,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	ids: [UInt64]
	)


```

### FindMarketDirectOffer (Escrowed And Soft)

[bidMarketDirectOfferEscrowed](transactions/bidMarketDirectOfferEscrowed.cdc)


[bidMarketDirectOfferSoft](transactions/bidMarketDirectOfferSoft.cdc)

```cadence
transaction(
	marketplace:Address,
	user: String,
	nftAliasOrIdentifier: String,
	// This is the ID of the NFT (NOT UUID)
	id: UInt64,
	ftAliasOrIdentifier:String,
	amount: UFix64,
	validUntil: UFix64?
	)

```

Direct Offer Soft here, after seller accept offer here, buyer has to send the fund over to complete the trade. Therefore we do not name this transaction "fulfill" for soft.

[fulfillMarketDirectOfferEscrowed](transactions/fulfillMarketDirectOfferEscrowed.cdc)

[acceptDirectOfferSoft](transactions/acceptDirectOfferSoft.cdc)

```cadence
transaction(
	marketplace:Address,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64
	)

```

Buyer has to fulfill the soft trade at last by sending the needed fund through (signed by Buyer)

[fulfillMarketAuctionSoft](transactions/fulfillMarketAuctionSoft.cdc)

```cadence
transaction(
	marketplace:Address,
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64,
	amount:UFix64
	)
```
