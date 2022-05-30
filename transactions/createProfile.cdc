import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import Dandy from "../contracts/Dandy.cdc"

transaction(name: String) {
	prepare(acct: AuthAccount) {
		//if we do not have a profile it might be stored under a different address so we will just remove it
		let profileCapFirst = acct.getCapability<&{Profile.Public}>(Profile.publicPath)
		if profileCapFirst.check() {
			return 
		}
		//the code below has some dead code for this specific transaction, but it is hard to maintain otherwise
		//SYNC with register
		//Add exising FUSD or create a new one and add it
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let usdcCap = acct.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
		if !usdcCap.check() {
				acct.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
        acct.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
        acct.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
				acct.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
		}

		let leaseCollection = acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			acct.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			acct.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let bidCollection = acct.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			acct.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			acct.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
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

		var created=false
		let profileCap = acct.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profile <-Profile.createUser(name:name, createdAt: "find")
			acct.save(<-profile, to: Profile.storagePath)
			acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			acct.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
			created=true
		}

		let profile=acct.borrow<&Profile.User>(from: Profile.storagePath)!
		if !profile.hasWallet("Flow") {
			let flowWallet=Profile.Wallet( name:"Flow", receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), balance:acct.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance), accept: Type<@FlowToken.Vault>(), names: ["flow"])
	
			profile.addWallet(flowWallet)
		}
		if !profile.hasWallet("FUSD") {
			profile.addWallet(Profile.Wallet( name:"FUSD", receiver:fusdReceiver, balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance), accept: Type<@FUSD.Vault>(), names: ["fusd", "stablecoin"]))
		}

		if !profile.hasWallet("USDC") {
			profile.addWallet(Profile.Wallet( name:"USDC", receiver:usdcCap, balance:acct.getCapability<&{FungibleToken.Balance}>(FiatToken.VaultBalancePubPath), accept: Type<@FiatToken.Vault>(), names: ["usdc", "stablecoin"]))
		}

 		//If find name not set and we have a profile set it.
		if profile.getFindName() == "" {
			profile.setFindName(name)
		}

		if created {
			profile.emitCreatedEvent()
		} else {
			profile.emitUpdatedEvent()
		}

		let receiverCap=acct.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!

		let tenant = tenantCapability.borrow()!
		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= acct.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath) 
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			acct.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			acct.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}

		let doeSaleType= Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
		let doeSalePublicPath=FindMarket.getPublicPath(doeSaleType, name: tenant.name)
		let doeSaleStoragePath= FindMarket.getStoragePath(doeSaleType, name:tenant.name)
		let doeSaleCap= acct.getCapability<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath) 
		if !doeSaleCap.check() {
			acct.save<@FindMarketDirectOfferEscrow.SaleItemCollection>(<- FindMarketDirectOfferEscrow.createEmptySaleItemCollection(tenantCapability), to: doeSaleStoragePath)
			acct.link<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath, target: doeSaleStoragePath)
		}

		let doeBidType= Type<@FindMarketDirectOfferEscrow.MarketBidCollection>()
		let doeBidPublicPath=FindMarket.getPublicPath(doeBidType, name: tenant.name)
		let doeBidStoragePath= FindMarket.getStoragePath(doeBidType, name:tenant.name)
		let doeBidCap= acct.getCapability<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath) 
		if !doeBidCap.check() {
			acct.save<@FindMarketDirectOfferEscrow.MarketBidCollection>(<- FindMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: doeBidStoragePath)
			acct.link<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath, target: doeBidStoragePath)
		}

		/// auctions that escrow ft
		let aeSaleType= Type<@FindMarketAuctionEscrow.SaleItemCollection>()
		let aeSalePublicPath=FindMarket.getPublicPath(aeSaleType, name: tenant.name)
		let aeSaleStoragePath= FindMarket.getStoragePath(aeSaleType, name:tenant.name)
		let aeSaleCap= acct.getCapability<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSalePublicPath) 
		if !aeSaleCap.check() {
			acct.save<@FindMarketAuctionEscrow.SaleItemCollection>(<- FindMarketAuctionEscrow.createEmptySaleItemCollection(tenantCapability), to: aeSaleStoragePath)
			acct.link<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSalePublicPath, target: aeSaleStoragePath)
		}

		let dosSaleType= Type<@FindMarketDirectOfferSoft.SaleItemCollection>()

		let dosSalePublicPath=FindMarket.getPublicPath(dosSaleType, name: tenant.name)
		let dosSaleStoragePath= FindMarket.getStoragePath(dosSaleType, name:tenant.name)

		let dosSaleCap= acct.getCapability<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath) 
		if !dosSaleCap.check() {
			acct.save<@FindMarketDirectOfferSoft.SaleItemCollection>(<- FindMarketDirectOfferSoft.createEmptySaleItemCollection(tenantCapability), to: dosSaleStoragePath)
			acct.link<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath, target: dosSaleStoragePath)
		}

		let dosBidType= Type<@FindMarketDirectOfferSoft.MarketBidCollection>()
		let dosBidPublicPath=FindMarket.getPublicPath(dosBidType, name: tenant.name)
		let dosBidStoragePath= FindMarket.getStoragePath(dosBidType, name:tenant.name)
		let dosBidCap= acct.getCapability<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath) 
		if !dosBidCap.check() {
			acct.save<@FindMarketDirectOfferSoft.MarketBidCollection>(<- FindMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: dosBidStoragePath)
			acct.link<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath, target: dosBidStoragePath)
		}

		let aeBidType= Type<@FindMarketAuctionEscrow.MarketBidCollection>()

		let aeBidPublicPath=FindMarket.getPublicPath(aeBidType, name: tenant.name)
		let aeBidStoragePath= FindMarket.getStoragePath(aeBidType, name:tenant.name)
		let aeBidCap= acct.getCapability<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath) 
		if !aeBidCap.check() {
			acct.save<@FindMarketAuctionEscrow.MarketBidCollection>(<- FindMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: aeBidStoragePath)
			acct.link<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath, target: aeBidStoragePath)
		}

	 /// auctions that refers FT so 'soft' auction
		let asSaleType= Type<@FindMarketAuctionSoft.SaleItemCollection>()
		let asSalePublicPath=FindMarket.getPublicPath(asSaleType, name: tenant.name)
		let asSaleStoragePath= FindMarket.getStoragePath(asSaleType, name:tenant.name)
		let asSaleCap= acct.getCapability<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(asSalePublicPath) 
		if !asSaleCap.check() {
			acct.save<@FindMarketAuctionSoft.SaleItemCollection>(<- FindMarketAuctionSoft.createEmptySaleItemCollection(tenantCapability), to: asSaleStoragePath)
			acct.link<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(asSalePublicPath, target: asSaleStoragePath)
		}

		let asBidType= Type<@FindMarketAuctionSoft.MarketBidCollection>()
		let asBidPublicPath=FindMarket.getPublicPath(asBidType, name: tenant.name)
		let asBidStoragePath= FindMarket.getStoragePath(asBidType, name:tenant.name)
		let asBidCap= acct.getCapability<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(asBidPublicPath) 
		if !asBidCap.check() {
			acct.save<@FindMarketAuctionSoft.MarketBidCollection>(<- FindMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: asBidStoragePath)
			acct.link<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(asBidPublicPath, target: asBidStoragePath)
		}
		//SYNC with register

	}
}
