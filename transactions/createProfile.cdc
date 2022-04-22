import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
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
		//TODO:this can be remove
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

		let receiverCap=acct.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)

		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let tenantCapability= FindMarketTenant.getFindTenantCapability()
		let tenant = tenantCapability.borrow()!

		let publicPath= tenant.getPublicPath(saleItemType) 
		let storagePath= tenant.getStoragePath(saleItemType) 

		let saleItemCap= acct.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>(publicPath) 
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			acct.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			acct.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}

		let doeSaleType= Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
		let doeSalePublicPath= tenant.getPublicPath(doeSaleType) 
		let doeSaleStoragePath= tenant.getStoragePath(doeSaleType)
		let doeSaleCap= acct.getCapability<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic}>(doeSalePublicPath) 
		if !doeSaleCap.check() {
			acct.save<@FindMarketDirectOfferEscrow.SaleItemCollection>(<- FindMarketDirectOfferEscrow.createEmptySaleItemCollection(tenantCapability), to: doeSaleStoragePath)
			acct.link<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic}>(doeSalePublicPath, target: doeSaleStoragePath)
		}

		let doeBidType= Type<@FindMarketDirectOfferEscrow.MarketBidCollection>()
		let doeBidPublicPath= tenant.getPublicPath(doeBidType) 
		let doeBidStoragePath= tenant.getStoragePath(doeBidType)
		let doeBidCap= acct.getCapability<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic}>(doeBidPublicPath) 
		if !doeBidCap.check() {
			acct.save<@FindMarketDirectOfferEscrow.MarketBidCollection>(<- FindMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: doeBidStoragePath)
			acct.link<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic}>(doeBidPublicPath, target: doeBidStoragePath)
		}

		/// auctions that escrow ft
		let aeSaleType= Type<@FindMarketAuctionEscrow.SaleItemCollection>()
		let aeSalePublicPath= tenant.getPublicPath(aeSaleType) 
		let aeSaleStoragePath= tenant.getStoragePath(aeSaleType)
		let aeSaleCap= acct.getCapability<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic}>(aeSalePublicPath) 
		if !aeSaleCap.check() {
			acct.save<@FindMarketAuctionEscrow.SaleItemCollection>(<- FindMarketAuctionEscrow.createEmptySaleItemCollection(tenantCapability), to: aeSaleStoragePath)
			acct.link<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic}>(aeSalePublicPath, target: aeSaleStoragePath)
		}

		let dosSaleType= Type<@FindMarketDirectOfferSoft.SaleItemCollection>()
		let dosSalePublicPath= tenant.getPublicPath(dosSaleType)
		let dosSaleStoragePath= tenant.getStoragePath(dosSaleType)
		let dosSaleCap= acct.getCapability<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic}>(dosSalePublicPath) 
		if !dosSaleCap.check() {
			acct.save<@FindMarketDirectOfferSoft.SaleItemCollection>(<- FindMarketDirectOfferSoft.createEmptySaleItemCollection(tenantCapability), to: dosSaleStoragePath)
			acct.link<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic}>(dosSalePublicPath, target: dosSaleStoragePath)
		}

		let dosBidType= Type<@FindMarketDirectOfferSoft.MarketBidCollection>()
		let dosBidPublicPath= tenant.getPublicPath(dosBidType) 
		let dosBidStoragePath= tenant.getStoragePath(dosBidType) 
		let dosBidCap= acct.getCapability<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic}>(dosBidPublicPath) 
		if !dosBidCap.check() {
			acct.save<@FindMarketDirectOfferSoft.MarketBidCollection>(<- FindMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: dosBidStoragePath)
			acct.link<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic}>(dosBidPublicPath, target: dosBidStoragePath)
		}

		let aeBidType= Type<@FindMarketAuctionEscrow.MarketBidCollection>()
		let aeBidPublicPath= tenant.getPublicPath(aeBidType) 
		let aeBidStoragePath= tenant.getStoragePath(aeBidType) 
		let aeBidCap= acct.getCapability<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic}>(aeBidPublicPath) 
		if !aeBidCap.check() {
			acct.save<@FindMarketAuctionEscrow.MarketBidCollection>(<- FindMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: aeBidStoragePath)
			acct.link<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic}>(aeBidPublicPath, target: aeBidStoragePath)
		}


	 /// auctions that refers FT so 'soft' auction
		let asSaleType= Type<@FindMarketAuctionSoft.SaleItemCollection>()
		let asSalePublicPath= tenant.getPublicPath(asSaleType)
		let asSaleStoragePath= tenant.getStoragePath(asSaleType) 
		let asSaleCap= acct.getCapability<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic}>(asSalePublicPath) 
		if !asSaleCap.check() {
			acct.save<@FindMarketAuctionSoft.SaleItemCollection>(<- FindMarketAuctionSoft.createEmptySaleItemCollection(tenantCapability), to: asSaleStoragePath)
			acct.link<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic}>(asSalePublicPath, target: asSaleStoragePath)
		}

		let asBidType= Type<@FindMarketAuctionSoft.MarketBidCollection>()
		let asBidPublicPath= tenant.getPublicPath(asBidType) 
		let asBidStoragePath= tenant.getStoragePath(asBidType)
		let asBidCap= acct.getCapability<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic}>(asBidPublicPath) 
		if !asBidCap.check() {
			acct.save<@FindMarketAuctionSoft.MarketBidCollection>(<- FindMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: asBidStoragePath)
			acct.link<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic}>(asBidPublicPath, target: asBidStoragePath)
		}
	}
}
