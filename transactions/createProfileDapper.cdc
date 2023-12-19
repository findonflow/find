import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(name: String) {
	prepare(account: auth(BorrowValue) &Account) {
		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let dandyCap= account.getCapability<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.storage.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}

		var created=false
		var updated=false
		let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profile <-Profile.createUser(name:name, createdAt: "find")
			account.storage.save(<-profile, to: Profile.storagePath)
			account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
			created=true
		}

		let profile=account.storage.borrow<&Profile.User>(from: Profile.storagePath)!

		if !profile.hasWallet("DUC") {
			let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
			profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance:account.getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapperUtilityCoin","dapper"]))
			updated=true
		}

		if !profile.hasWallet("FUT") {
			let futReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
			profile.addWallet(Profile.Wallet( name:"FUT", receiver:futReceiver, balance:account.getCapability<&{FungibleToken.Balance}>(/public/flowUtilityTokenBalance), accept: Type<@FlowUtilityToken.Vault>(), tags: ["fut", "flowUtilityToken","dapper"]))
			updated=true
		}

		profile.emitCreatedEvent()

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!

		let tenant = tenantCapability.borrow()!

		let dosSaleType= Type<@FindMarketDirectOfferSoft.SaleItemCollection>()
		let dosSalePublicPath=FindMarket.getPublicPath(dosSaleType, name: tenant.name)
		let dosSaleStoragePath= FindMarket.getStoragePath(dosSaleType, name:tenant.name)
		let dosSaleCap= account.getCapability<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath)
		if !dosSaleCap.check() {
			account.storage.save<@FindMarketDirectOfferSoft.SaleItemCollection>(<- FindMarketDirectOfferSoft.createEmptySaleItemCollection(tenantCapability), to: dosSaleStoragePath)
			account.link<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath, target: dosSaleStoragePath)
		}

		let leaseTenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!
		let leaseTenant = leaseTenantCapability.borrow()!

		let leaseDOSSaleItemType= Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()
		let leaseDOSPublicPath=leaseTenant.getPublicPath(leaseDOSSaleItemType)
		let leaseDOSStoragePath= leaseTenant.getStoragePath(leaseDOSSaleItemType)
		let leaseDOSSaleItemCap= account.getCapability<&FindLeaseMarketDirectOfferSoft.SaleItemCollection{FindLeaseMarketDirectOfferSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOSPublicPath)
		if !leaseDOSSaleItemCap.check() {
			//The link here has to be a capability not a tenant, because it can change.
			account.storage.save<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseDOSStoragePath)
			account.link<&FindLeaseMarketDirectOfferSoft.SaleItemCollection{FindLeaseMarketDirectOfferSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOSPublicPath, target: leaseDOSStoragePath)
		}

	}
}
