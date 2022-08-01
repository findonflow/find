import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
// import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"
// import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(marketplace:Address, nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {
	
	let saleItems : &FindMarketSale.SaleItemCollection?
	let pointer : FindViews.AuthNFTPointer
	let vaultType : Type

	prepare(account: AuthAccount) {

		//the code below has some dead code for this specific transaction, but it is hard to maintain otherwise
		//SYNC with register
		//Add exising FUSD or create a new one and add it
		let name = account.address.toString()
		let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let usdcCap = account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
		if !usdcCap.check() {
				account.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
        account.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
        account.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
				account.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
		}

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let bidCollection = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			account.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			account.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}

		let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		let dandyCapPrivate= account.getCapability<&{Dandy.CollectionPublic}>(Dandy.CollectionPrivatePath)
		if !dandyCapPrivate.check() {
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		var created=false
		var updated=false
		let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profile <-Profile.createUser(name:name, createdAt: "find")
			account.save(<-profile, to: Profile.storagePath)
			account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
			created=true
		}

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!

		if !profile.hasWallet("Flow") {
			let flowWallet=Profile.Wallet( name:"Flow", receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), balance:account.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance), accept: Type<@FlowToken.Vault>(), tags: ["flow"])
	
			profile.addWallet(flowWallet)
			updated=true
		}
		if !profile.hasWallet("FUSD") {
			profile.addWallet(Profile.Wallet( name:"FUSD", receiver:fusdReceiver, balance:account.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance), accept: Type<@FUSD.Vault>(), tags: ["fusd", "stablecoin"]))
			updated=true
		}

		if !profile.hasWallet("USDC") {
			profile.addWallet(Profile.Wallet( name:"USDC", receiver:usdcCap, balance:account.getCapability<&{FungibleToken.Balance}>(FiatToken.VaultBalancePubPath), accept: Type<@FiatToken.Vault>(), tags: ["usdc", "stablecoin"]))
			updated=true
		}

		if created {
			profile.emitCreatedEvent()
		} else if updated {
			profile.emitUpdatedEvent()
		}

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
		let tenantCapability= FindMarket.getTenantCapability(marketplace)!

		let tenant = tenantCapability.borrow()!
		let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
		let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

		let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath) 
		if !saleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
			account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
		}

		let doeSaleType= Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
		let doeSalePublicPath=FindMarket.getPublicPath(doeSaleType, name: tenant.name)
		let doeSaleStoragePath= FindMarket.getStoragePath(doeSaleType, name:tenant.name)
		let doeSaleCap= account.getCapability<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath) 
		if !doeSaleCap.check() {
			account.save<@FindMarketDirectOfferEscrow.SaleItemCollection>(<- FindMarketDirectOfferEscrow.createEmptySaleItemCollection(tenantCapability), to: doeSaleStoragePath)
			account.link<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath, target: doeSaleStoragePath)
		}

		let doeBidType= Type<@FindMarketDirectOfferEscrow.MarketBidCollection>()
		let doeBidPublicPath=FindMarket.getPublicPath(doeBidType, name: tenant.name)
		let doeBidStoragePath= FindMarket.getStoragePath(doeBidType, name:tenant.name)
		let doeBidCap= account.getCapability<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath) 
		if !doeBidCap.check() {
			account.save<@FindMarketDirectOfferEscrow.MarketBidCollection>(<- FindMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: doeBidStoragePath)
			account.link<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath, target: doeBidStoragePath)
		}

		/// auctions that escrow ft
		let aeSaleType= Type<@FindMarketAuctionEscrow.SaleItemCollection>()
		let aeSalePublicPath=FindMarket.getPublicPath(aeSaleType, name: tenant.name)
		let aeSaleStoragePath= FindMarket.getStoragePath(aeSaleType, name:tenant.name)
		let aeSaleCap= account.getCapability<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSalePublicPath) 
		if !aeSaleCap.check() {
			account.save<@FindMarketAuctionEscrow.SaleItemCollection>(<- FindMarketAuctionEscrow.createEmptySaleItemCollection(tenantCapability), to: aeSaleStoragePath)
			account.link<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSalePublicPath, target: aeSaleStoragePath)
		}

		let dosSaleType= Type<@FindMarketDirectOfferSoft.SaleItemCollection>()

		let dosSalePublicPath=FindMarket.getPublicPath(dosSaleType, name: tenant.name)
		let dosSaleStoragePath= FindMarket.getStoragePath(dosSaleType, name:tenant.name)

		let dosSaleCap= account.getCapability<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath) 
		if !dosSaleCap.check() {
			account.save<@FindMarketDirectOfferSoft.SaleItemCollection>(<- FindMarketDirectOfferSoft.createEmptySaleItemCollection(tenantCapability), to: dosSaleStoragePath)
			account.link<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath, target: dosSaleStoragePath)
		}

		let dosBidType= Type<@FindMarketDirectOfferSoft.MarketBidCollection>()
		let dosBidPublicPath=FindMarket.getPublicPath(dosBidType, name: tenant.name)
		let dosBidStoragePath= FindMarket.getStoragePath(dosBidType, name:tenant.name)
		let dosBidCap= account.getCapability<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath) 
		if !dosBidCap.check() {
			account.save<@FindMarketDirectOfferSoft.MarketBidCollection>(<- FindMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: dosBidStoragePath)
			account.link<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath, target: dosBidStoragePath)
		}

		let aeBidType= Type<@FindMarketAuctionEscrow.MarketBidCollection>()

		let aeBidPublicPath=FindMarket.getPublicPath(aeBidType, name: tenant.name)
		let aeBidStoragePath= FindMarket.getStoragePath(aeBidType, name:tenant.name)
		let aeBidCap= account.getCapability<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath) 
		if !aeBidCap.check() {
			account.save<@FindMarketAuctionEscrow.MarketBidCollection>(<- FindMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: aeBidStoragePath)
			account.link<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath, target: aeBidStoragePath)
		}

	 /// auctions that refers FT so 'soft' auction
		let asSaleType= Type<@FindMarketAuctionSoft.SaleItemCollection>()
		let asSalePublicPath=FindMarket.getPublicPath(asSaleType, name: tenant.name)
		let asSaleStoragePath= FindMarket.getStoragePath(asSaleType, name:tenant.name)
		let asSaleCap= account.getCapability<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(asSalePublicPath) 
		if !asSaleCap.check() {
			account.save<@FindMarketAuctionSoft.SaleItemCollection>(<- FindMarketAuctionSoft.createEmptySaleItemCollection(tenantCapability), to: asSaleStoragePath)
			account.link<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(asSalePublicPath, target: asSaleStoragePath)
		}

		let asBidType= Type<@FindMarketAuctionSoft.MarketBidCollection>()
		let asBidPublicPath=FindMarket.getPublicPath(asBidType, name: tenant.name)
		let asBidStoragePath= FindMarket.getStoragePath(asBidType, name:tenant.name)
		let asBidCap= account.getCapability<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(asBidPublicPath) 
		if !asBidCap.check() {
			account.save<@FindMarketAuctionSoft.MarketBidCollection>(<- FindMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: asBidStoragePath)
			account.link<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(asBidPublicPath, target: asBidStoragePath)
		}

		let leaseTenantCapability= FindMarket.getTenantCapability(FindMarket.getTenantAddress("findLease")!)!

		let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
		let leasePublicPath=FindMarket.getPublicPath(leaseSaleItemType, name: "findLease")
		let leaseStoragePath= FindMarket.getStoragePath(leaseSaleItemType, name:"findLease")
		let leaseSaleItemCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath) 
		if !leaseSaleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
			account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
		}

		let leaseASSaleItemType= Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>()
		let leaseASPublicPath=FindMarket.getPublicPath(leaseASSaleItemType, name: "findLease")
		let leaseASStoragePath= FindMarket.getStoragePath(leaseASSaleItemType, name:"findLease")
		let leaseASSaleItemCap= account.getCapability<&FindLeaseMarketAuctionSoft.SaleItemCollection{FindLeaseMarketAuctionSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseASPublicPath) 
		if !leaseASSaleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindLeaseMarketAuctionSoft.SaleItemCollection>(<- FindLeaseMarketAuctionSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseASStoragePath)
			account.link<&FindLeaseMarketAuctionSoft.SaleItemCollection{FindLeaseMarketAuctionSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseASPublicPath, target: leaseASStoragePath)
		}


		let leaseASBidType= Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>()
		let leaseASBidPublicPath=FindMarket.getPublicPath(leaseASBidType, name: "findLease")
		let leaseASBidStoragePath= FindMarket.getStoragePath(leaseASBidType, name: "findLease")
		let leaseASBidCap= account.getCapability<&FindLeaseMarketAuctionSoft.MarketBidCollection{FindLeaseMarketAuctionSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath) 
		if !leaseASBidCap.check() {
			account.save<@FindLeaseMarketAuctionSoft.MarketBidCollection>(<- FindLeaseMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseASBidStoragePath)
			account.link<&FindLeaseMarketAuctionSoft.MarketBidCollection{FindLeaseMarketAuctionSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath, target: leaseASBidStoragePath)
		}

		// let leaseAESaleItemType= Type<@FindLeaseMarketAuctionEscrow.SaleItemCollection>()
		// let leaseAEPublicPath=FindMarket.getPublicPath(leaseAESaleItemType, name: "findLease")
		// let leaseAEStoragePath= FindMarket.getStoragePath(leaseAESaleItemType, name:"findLease")
		// let leaseAESaleItemCap= account.getCapability<&FindLeaseMarketAuctionEscrow.SaleItemCollection{FindLeaseMarketAuctionEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseAEPublicPath) 
		// if !leaseAESaleItemCap.check() {
		// 	//The link here has to be a capability not a tenant, because it can change.
		// 	account.save<@FindLeaseMarketAuctionEscrow.SaleItemCollection>(<- FindLeaseMarketAuctionEscrow.createEmptySaleItemCollection(leaseTenantCapability), to: leaseAEStoragePath)
		// 	account.link<&FindLeaseMarketAuctionEscrow.SaleItemCollection{FindLeaseMarketAuctionEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseAEPublicPath, target: leaseAEStoragePath)
		// }

		// let leaseAEBidType= Type<@FindLeaseMarketAuctionEscrow.MarketBidCollection>()
		// let leaseAEBidPublicPath=FindMarket.getPublicPath(leaseAEBidType, name: "findLease")
		// let leaseAEBidStoragePath= FindMarket.getStoragePath(leaseAEBidType, name: "findLease")
		// let leaseAEBidCap= account.getCapability<&FindLeaseMarketAuctionEscrow.MarketBidCollection{FindLeaseMarketAuctionEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseAEBidPublicPath) 
		// if !leaseAEBidCap.check() {
		// 	account.save<@FindLeaseMarketAuctionEscrow.MarketBidCollection>(<- FindLeaseMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseAEBidStoragePath)
		// 	account.link<&FindLeaseMarketAuctionEscrow.MarketBidCollection{FindLeaseMarketAuctionEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseAEBidPublicPath, target: leaseAEBidStoragePath)
		// }

		let leaseDOSSaleItemType= Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()
		let leaseDOSPublicPath=FindMarket.getPublicPath(leaseDOSSaleItemType, name: "findLease")
		let leaseDOSStoragePath= FindMarket.getStoragePath(leaseDOSSaleItemType, name:"findLease")
		let leaseDOSSaleItemCap= account.getCapability<&FindLeaseMarketDirectOfferSoft.SaleItemCollection{FindLeaseMarketDirectOfferSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOSPublicPath) 
		if !leaseDOSSaleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.save<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseDOSStoragePath)
			account.link<&FindLeaseMarketDirectOfferSoft.SaleItemCollection{FindLeaseMarketDirectOfferSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOSPublicPath, target: leaseDOSStoragePath)
		}

		let leaseDOSBidType= Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>()
		let leaseDOSBidPublicPath=FindMarket.getPublicPath(leaseDOSBidType, name: "findLease")
		let leaseDOSBidStoragePath= FindMarket.getStoragePath(leaseDOSBidType, name: "findLease")
		let leaseDOSBidCap= account.getCapability<&FindLeaseMarketDirectOfferSoft.MarketBidCollection{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath) 
		if !leaseDOSBidCap.check() {
			account.save<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOSBidStoragePath)
			account.link<&FindLeaseMarketDirectOfferSoft.MarketBidCollection{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath, target: leaseDOSBidStoragePath)
		}

		// let leaseDOESaleItemType= Type<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>()
		// let leaseDOEPublicPath=FindMarket.getPublicPath(leaseDOESaleItemType, name: "findLease")
		// let leaseDOEStoragePath= FindMarket.getStoragePath(leaseDOESaleItemType, name:"findLease")
		// let leaseDOESaleItemCap= account.getCapability<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection{FindLeaseMarketDirectOfferEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOEPublicPath) 
		// if !leaseDOESaleItemCap.check() {
		// 	//The link here has to be a capability not a tenant, because it can change.
		// 	account.save<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>(<- FindLeaseMarketDirectOfferEscrow.createEmptySaleItemCollection(leaseTenantCapability), to: leaseDOEStoragePath)
		// 	account.link<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection{FindLeaseMarketDirectOfferEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOEPublicPath, target: leaseDOEStoragePath)
		// }

		// let leaseDOEBidType= Type<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>()
		// let leaseDOEBidPublicPath=FindMarket.getPublicPath(leaseDOEBidType, name: "findLease")
		// let leaseDOEBidStoragePath= FindMarket.getStoragePath(leaseDOEBidType, name: "findLease")
		// let leaseDOEBidCap= account.getCapability<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection{FindLeaseMarketDirectOfferEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOEBidPublicPath) 
		// if !leaseDOEBidCap.check() {
		// 	account.save<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>(<- FindLeaseMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOEBidStoragePath)
		// 	account.link<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection{FindLeaseMarketDirectOfferEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOEBidPublicPath, target: leaseDOEBidStoragePath)
		// }
		//SYNC with register

		// Get supported NFT and FT Information from Registries from input alias
		let nft = getCollectionData(nftAliasOrIdentifier) 
		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		let providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(nft.privatePath)

		/* Ben : Question -> Either client will have to provide the path here or agree that we set it up for the user */
		if !providerCap.check() {
				account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
					nft.privatePath,
					target: nft.storagePath
			)
		}
		// Get the salesItemRef from tenant
		self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
		self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
		self.vaultType= ft.type
	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})
	}
}

pub fun getCollectionData(_ nftIdentifier: String) : NFTCatalog.NFTCollectionData {
	let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData
}