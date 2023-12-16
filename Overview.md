# .find

.find is a solution that aims to make it easier to .find people and their things on the flow blockchain. It is live on mainnet since Dec 13th 2021 at https://find.xyz

If you have questions implementing .find services, please reach out to any of us in discord.gg/findonflow

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
- Onchain Identity
  - Profile
  - Related Accounts
- Marketplace
- NFT Batch Minter
- NFT Pack
- Community Tools Wrapper
- Social Networking Tools (Thoughts)

# Name services Contracts

[FIND](./contracts/FIND.cdc) contract is the heart of the FIND name service.
It defines a name lease (which is not implementing NFT standard therefore it is not an NFT), and the usage around it.

A Lease is a permission to own and use the domain name within a period of time (in .find's case that would be an year since register in general.) Lease owner can link themselves and their wallet address with ${name}.find. Smart contracts that implement FIND can resolve the lease owner address and tell who that is without sending in the clumsy and unreadable length wallet address.

## Lease Attribute

Leases are created and handled as resource on flow. So that they are properly handled and stored.

### Attributes :

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

[resolve](scripts/resolve.cdc)

```cadence
import FIND

pub fun main(name: String) : Address? {
	return FIND.resolve(name)
}
```

- get the name of an account

[reverseLookup](scripts/reverseLookup.cdc)

```cadence
pub fun main(input: Address) : String? {
	return FIND.reverseLookup(input)
}
```

# Identity (Profile)

Identity and Personalized descriptions are important assets and features to .find and users. They show how a User want themselves to look like on chain and identify who they are besides the lengthy address.

The information is stored under Profile resource in [Profile](./contracts/Profile.cdc) contract.

We have a primary social tools which users can follow / unfollow / setPrivate or ban other users.

## Contract Functions

```cadence

	// Identity and descriptions can be fetched from below functions
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

		// User resource is the Profile that we are referring to.
		// Notice that User resource implments "FungibleToken.Receiver"
		// Which means that it can be passed elsewhere as a FungibleToken Switchboard
		pub resource User: Public, Owner, FungibleToken.Receiver {
			// In deposit function,
			// The profile is smart enough to identify the vault type and deposit to corresponding FT vault.
			// Even if the wallet is not set to link with profile, we still tries to borrow vaults from standard path and deposit it.
			pub fun deposit(from: @FungibleToken.Vault)

			// Wallets related functions
			pub fun hasWallet(_ name: String) : Bool
			pub fun getWallets() : [Wallet]
			pub fun addWallet(_ val: Wallet)
			pub fun removeWallet(_ val: String)
			pub fun setWallets(_ val: [Wallet])

			// Followers related functions
			pub fun removeFollower(_ val: Address)
			pub fun follows(_ address: Address) : Bool
			pub fun follow(_ address: Address, tags:[String])
			pub fun unfollow(_ address: Address)
		}
	}
```

## Interaction Template (Profile)

[createProfile](transactions/createProfile.cdc)

```cadence
transaction(
	// This is NOT the find name
	// This is the profile name that will be displayed on profile only
	name: String
)
```

[register](transactions/register.cdc)

```cadence
transaction(
	// This is the find name to be purchased
	name: String,
	// Amount needed :
	// 3 characters : 500 FUSD,
	// 4 characters : 100 FUSD,
	// 5 characters or above : 5 FUSD
	amount: UFix64
	)

```

[editProfile](transactions/editProfile.cdc)

```cadence
transaction(
	name:String,
	description: String,
	// This should be the image URL to display user's profile image
	avatar: String,
	tags:[String],
	allowStoringFollowers: Bool,

	// For linkTitles, linkTypes and linkUrls :
	// We will create a struct with these 3 maps,
	// So make sure the keys of these 3 maps are the same,
	// and put the title, types and urls in

	// titles : ways to name the link
	linkTitles : {String: String},
	// types : Can be link, discord, twitter, linkedIn so on
	linkTypes: {String:String},
	// urls: urls
	linkUrls : {String:String},

	// removeLinks : array of link titles wanted to remove
	removeLinks : [String]
	)

```

[follow](transactions/follow.cdc)

```cadence
transaction(
	// map of {User in string (find name or address) : [tag]}
	follows:{String : [String]}
	)

```

[unfollow](transactions/unfollow.cdc)

```cadence
transaction(
// array of [User in string (find name or address)]
	unfollows:[String]
	)

```

# Identity (Related Account)

Related Accounts enable user to build their own social networks and wallets on flow and on other chains.

User can add their flow wallets / wallets on other chains by network and name. They can also add others wallet as "contact". Currently, if both accounts added each other as related wallet, we would take that as a "verified" trust.

## Contract Functions

```cadence

	pub contract FindRelatedAccounts {
		pub resource interface Public{
			// get all registered related flow accounts
			pub fun getFlowAccounts() : {String: [Address]}
			// get all registered related accounts in specific network
			pub fun getRelatedAccounts(_ network: String) : {String : [String]}
			// get all registered related accounts : {Network : Addresses}
			pub fun getAllRelatedAccounts() : {String : {String : [String]}}
			// get all registered related accounts : {Network : AccountInfo struct}
			pub fun getAllRelatedAccountInfo() : {String : AccountInformation}
			// verify ensure this wallet address exist under the network
			pub fun verify(network: String, address: String) : Bool
			// linked ensure this wallet is linked in both wallet with the same name (but not socially linked only)
			// only supports flow for now
			pub fun linked(name: String, network: String, address: Address) : Bool
			pub fun getAccount(name: String, network: String, address: String) : AccountInformation?
		}

	}
```

## Interaction Template (Related Accounts)

[setRelatedAccount](transactions/setRelatedAccount.cdc)

```cadence
transaction(
	// how user would like to name this wallet for their convenience
	name: String,
	// flow address in string or find name (we resolve this and get the address from it)
	target: String
	)

```

[addRelatedAccount](transactions/addRelatedAccount.cdc)

```cadence
transaction(
	// how user would like to name this wallet for their convenience
	name: String,
	// network of the wallet (right now we are using "Flow" and "Ethereum")
	network: String,
	// string address to be added as wallet
	address: String
	)

```

[updateRelatedFlowAccount](transactions/updateRelatedFlowAccount.cdc)

```cadence
transaction(
	// wallet to be updated
	name: String,
	oldAddress: Address,
	address: Address
	)
```

[updateRelatedAccount](transactions/updateRelatedAccount.cdc)

```cadence
transaction(
	name: String,
	network: String,
	oldAddress:String,
	address: String
	)

```

[removeRelatedAccount](transactions/removeRelatedAccount.cdc)

```cadence
transaction(
	name: String,
	// Flow network also works here
	network: String,
	address: String
	)

```

### Scripts

[getAllRelatedAccounts](scripts/getAllRelatedAccounts.cdc)

```cadence
pub fun main(
	user: Address
	// @return : {Network : {Wallet : [wallet address]}}
	) : {String : {String : [String]}}

```

Related accounts are also exposed in getStatus script under accounts with Emerald City Emerald ID.

Report -> FINDReport -> accounts

[getAllRelatedAccounts](scripts/getAllRelatedAccounts.cdc)

```cadence
pub fun main(
	user: String
	) : Report?

pub struct Report {
	pub let FINDReport: FINDReport?
}

pub struct FINDReport{
	pub let accounts : [AccountInformation]?
}

pub struct AccountInformation {
	pub let name: String
	pub let address: String
	pub let network: String
	pub let trusted: Bool
	pub let node: String
}

```

# Asset Management

## FungibleToken

FungibleTokens are exposed under Find Profile contracts.
As soon as a user adds his/her wallet to Profile, it can be viewable in Profile report. By default we always add FUSD / USDC / Flow token for non-Dapper Users if they initiate their account on .find page.

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

		pub struct UserReport {
			pub let findName: String
			pub let createdAt: String
			pub let address: Address
			pub let name: String
			pub let gender: String
			pub let description: String
			pub let tags: [String]
			pub let avatar: String
			pub let links: {String:Link}
			// wallet status are exposed in this field
			pub let wallets: [WalletProfile]
			pub let following: [FriendStatus]
			pub let followers: [FriendStatus]
			pub let allowStoringFollowers: Bool
		}

	}
```

### Scripts

NFTs can be fetched from these scripts

- NFT script to fetch user collection with only IDs
  [getNFTCatalogIDs](./scripts/getNFTCatalogIDs.cdc)

```cadence
// User : String address or find name
// collections : target collection or empty if no specific collection wanted

// @return a map of collection to ids
pub fun main(
	user: String,
	collections: [String]
	) : {String : ItemReport}

pub struct ItemReport {
	// Mapping of collection to no. of ids
	pub let length : Int
	pub let extraIDs : [UInt64]
	// Shard means which source we fetch information from. In this case it will always be NFTCatalog
	pub let shard : String
	// This is needed when we would like to fetch further IDs
	pub let extraIDsIdentifier : String
	// collectionName for display
	pub let collectionName: String
}
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
pub fun main(
	user: String,
	project:String,
	id: UInt64,
	views: [String]
	) : NFTDetailReport?

pub struct NFTDetailReport {
	pub let findMarket: {String : FindMarket.SaleItemInformation}
	pub let storefront: FindUserStatus.StorefrontListing?
	pub let storefrontV2: FindUserStatus.StorefrontListing?
	pub let flowty: FindUserStatus.FlowtyListing?
	pub let flowtyRental: FindUserStatus.FlowtyRental?
	pub let flovatar: FindUserStatus.FlovatarListing?
	pub let flovatarComponent: FindUserStatus.FlovatarComponentListing?
	pub let nftDetail: NFTDetail?
	pub let allowedListingActions: {String : ListingTypeReport}
	pub let dapperAllowedListingActions: {String : ListingTypeReport}
	pub let linkedForMarket : Bool?
}
```

# Marketplace

The .find marketplace doesn't use StoreFront because we started on this before NFTStorefront is there. .find marketplace supports more than just direct sales but also Offers, Auctions and non-Escrowed Auctions (no funds locked for auctions)

One feature to mention is that FindMarket supports multi-tenant model. That is each address can host a FindTenant and manage their own market rules (allowing specific listings , NFTs and FTs) and Cuts.

Users can interact with each tenant easily by just changing the "tenant" parameter in the transactions

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
transaction(id: UInt64, directSellPrice:UFix64) {

	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer

	prepare(account: AuthAccount) {

		// Get tenant from marketplace address
		let marketplace = FindMarket.getFindTenantAddress()
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!
		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()

		let tenant = tenantCapability.borrow()!

		// get saleItemCollection from tenant specific storage path and saleItemType (in this case FindMarketSale)
		self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))

		// getProvider private capability of the selling NFT
		var providerCap=account.getCapability<&{NonFungibleToken.Provider, ViewResolver.ResolverCollection, NonFungibleToken.CollectionPublic}>(${NFT_Provider_Private_Path})

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

transaction(user: String, id: UInt64, amount: UFix64) {

	var targetCapability : Capability<&{NonFungibleToken.Receiver}>
	let walletReference : &FungibleToken.Vault

	let saleItemsCap: Capability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>

	prepare(account: AuthAccount) {

		let marketplace = FindMarket.getFindTenantAddress()
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
	// This is the UUID of the NFT
	ids: [UInt64]
	)

```

### FindMarketAuction (Escrowed And Soft)

[listAuctionEscrowed](transactions/listNFTForAuctionSoft.cdc)

[listAuctionSoft](transactions/listNFTForAuctionSoft.cdc)

```cadence
transaction(
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
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64
	)

```

Buyer has to fulfill the soft trade at last by sending the needed fund through (signed by Buyer)

[fulfillMarketAuctionSoft](transactions/fulfillMarketAuctionSoft.cdc)

```cadence
transaction(
	// This is the UUID of the NFT
	// Because we do not send in types here, id has to be unique for the listing
	id: UInt64,
	amount:UFix64
	)
```

# Thoughts

[Thoughts](contracts/FindThoughts.cdc) is a fully on-chain social networking / posting platform.

You can post thought (what we call Think like Tweet as to Twitter), share medias, reThink (quote and post on top), edit, delete, hide and react to thoughts.

Thoughts are still in alpha stage, we are still forging the ability to share and point to NFTs / any onchain assets, adding reply function, publish with tag and get fetched / categorized by the tags, etc.

This will be very important part of social mapping

## Contract Function

```cadence
// ** Thoughts are NOT NFTs as they are not meant to be.
// They should not be freely moved or regarded as NFT assets
pub contract FindThoughts {

	// These are the fields in the Thought and exposed through ThoughtPublic interface to enable the above mentinoned functions

	// One thing to mention is that Thought supports NFT views.
	// We implemented FindViews.ViewReadPointer in thoughts, therefore it can be used to point to NFTs (and fetch NFT information)
	pub resource interface ThoughtPublic {
		pub let id: UInt64
		pub let creator: Address
		pub var header: String
		pub var body: String
		pub let created: UFix64
		pub var lastUpdated: UFix64?
		pub let medias: [MetadataViews.Media]
		pub let nft: [FindViews.ViewReadPointer]
		pub var tags: [String]
		pub var reacted: {Address : String}
		pub var reactions: {String : Int}

		access(contract) fun internal_react(user: Address, reaction: String?)
		pub fun getQuotedThought() : ThoughtPointer?
		pub fun getHide() : Bool
	}

	// CollectionPublic interface exposes below functions to the public
	pub resource interface CollectionPublic {
		pub fun contains(_ id: UInt64) : Bool
		pub fun getIDs() : [UInt64]
		pub fun borrowThoughtPublic(_ id: UInt64) : &FindThoughts.Thought{FindThoughts.ThoughtPublic}
	}

	// Collection
	pub resource Collection : CollectionPublic, ViewResolver.ResolverCollection {
		// Publish a thought with optional media, NFTPointer or quotes
		pub fun publish(header: String , body: String , tags: [String], media: MetadataViews.Media?, nftPointer: FindViews.ViewReadPointer?, quote: FindThoughts.ThoughtPointer?)
		pub fun delete(_ id: UInt64)
		pub fun hide(id: UInt64, hide: Bool)

		// react to OTHER user's thought
		pub fun react(user: Address, id: UInt64, reaction: String?)
	}

}

```

### Interaction Template

[publishFindThought](transactions/publishFindThought.cdc)

```cadence
transaction(
	// Header of the thought
	header: String ,
	// Body of the thought
	body: String ,
	// Tags of the thought
	tags: [String],
	// Media details if any
	mediaHash: String?,
	mediaType: String?,
	// NFT Details if any
	quoteNFTOwner: Address?,
	quoteNFTType: String?,
	quoteNFTId: UInt64?,
	// Quoted Thoughts if any
	quoteCreator: Address?,
	quoteId: UInt64?
	)

```

[editFindThought](transactions/editFindThought.cdc)

```cadence
transaction(
	// Thought ID
	id: UInt64,
	// new header
	header: String ,
	// new body
	body: String,
	// new tags
	tags: [String]
	)

```

[deleteFindThoughts](transactions/deleteFindThoughts.cdc)

```cadence
transaction(
	// Thought IDs
	ids: [UInt64]
	)
```

[deleteFindThoughts](transactions/deleteFindThoughts.cdc)

```cadence
transaction(
	// Thought IDs
	ids: [UInt64],
	// corresponding hide status
	// true = hide
	// false = show
	hide: [Bool]
	)
```

[reactToFindThoughts](transactions/reactToFindThoughts.cdc)

```cadence
transaction(
	// find name / string addrss of thought creator
	users: [String],
	// corresponding ids of thought
	ids: [UInt64] ,
	// corresponding reactions
	reactions: [String],
	// find name / string addrss of thought creator to undo reaction
	undoReactionUsers: [String],
	// corresponding ids of thought to undo reaction
	undoReactionIds: [UInt64]
	)

```

### Scripts

Scripts to fetch different user's thoughts

[getFindThoughts](scripts/getFindThoughts.cdc)

```cadence
pub fun main(
	// owner of the thought
	addresses: [Address],
	// corresponding thought IDs
	ids: [UInt64]
	) : [Thought]
```

Scripts to fetch one user's all thoughts

[getOwnedFindThoughts](scripts/getOwnedFindThoughts.cdc)

```cadence
pub fun main(
	// owner of the thought
	address: Address
	) : [Thought]

```

returning object

```cadence
pub struct Thought {
	pub let id: UInt64
	pub let creator: Address
	pub let creatorName: String?
	pub var creatorProfileName: String?
	pub var creatorAvatar: String?
	pub var header: String?
	pub var body: String?
	pub let created: UFix64?
	pub var lastUpdated: UFix64?
	pub let medias: {String : String}
	pub let nft: [FindMarket.NFTInfo]
	pub var tags: [String]
	pub var reacted: {String : [User]}
	pub var reactions: {String : Int}
	pub var reactedUsers: {String : [String]}
	pub var quotedThought: Thought?
	pub let hidden: Bool?
	}
```

# Name Voucher

Name voucher is an NFT that enables owner to register / renew / extend a .find name lease.
They are restricted by the minimum number of characters
E.g. voucher with 3-characters can renew any lease / register any FREE lease ,
voucher with 4-characters can only do so to 4-characters or above leases

### Interaction Template

[redeemNameVoucher](transactions/redeemNameVoucher.cdc)

```cadence
transaction(
	// id of the voucher if the voucher is in collection
	// OR
	// ticket id of the LostAndFound Inbox
	id: UInt64,
	// .find name wanted to register or renew (that is owned by the signer)
	name: String
	)

```
