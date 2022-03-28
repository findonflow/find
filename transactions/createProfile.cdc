import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import Dandy from "../contracts/Dandy.cdc"

//really not sure on how to input links here.)
transaction(name: String) {
	prepare(acct: AuthAccount) {
		//if we do not have a profile it might be stored under a different address so we will just remove it
		let profileCap = acct.getCapability<&{Profile.Public}>(Profile.publicPath)
		if profileCap.check() {
			return 
		}

		let dandyCap= acct.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			acct.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			acct.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			acct.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let profile <-Profile.createUser(name:name, createdAt: "find")

		//Add exising FUSD or create a new one and add it
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let fusdWallet=Profile.Wallet(
			name:"FUSD", 
			receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver),
			balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
			accept: Type<@FUSD.Vault>(),
			names: ["fusd", "stablecoin"]
		)

		profile.addWallet(fusdWallet)

		let flowWallet=Profile.Wallet(
			name:"Flow", 
			receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
			balance:acct.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance),
			accept: Type<@FlowToken.Vault>(),
			names: ["flow"]
		)
		profile.addWallet(flowWallet)
		let leaseCollection = acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			acct.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			acct.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}
		profile.addCollection(Profile.ResourceCollection("FINDLeases",leaseCollection, Type<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(), ["find", "leases"]))

		let bidCollection = acct.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			acct.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			acct.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}
		profile.addCollection(Profile.ResourceCollection( "FINDBids", bidCollection, Type<&FIND.BidCollection{FIND.BidCollectionPublic}>(), ["find", "bids"]))


		acct.save(<-profile, to: Profile.storagePath)
		acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
		acct.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)

		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let tenant= FindMarket.getFindTenant()
		let publicPath= tenant.getPublicPath(saleItemType) ?? panic("Direct sale not active for this tenant")
		let storagePath= tenant.getStoragePath(saleItemType) ?? panic("Direct sale not active for this tenant")

		let saleItemCap= acct.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>(publicPath) 
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			acct.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenant), to: storagePath)
			acct.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}
	}
}
