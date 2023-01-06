import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(leaseName: String, ftAliasOrIdentifier:String, amount: UFix64, validUntil: UFix64?) {

	let bidsReference: &FindLeaseMarketDirectOfferSoft.MarketBidCollection?
	let ftVaultType: Type

	prepare(account: AuthAccount) {
		
		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		self.ftVaultType = ft.type

		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let leaseDOSBidType= Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>()
		let leaseDOSBidPublicPath=FindMarket.getPublicPath(leaseDOSBidType, name: "findLease")
		let leaseDOSBidStoragePath= FindMarket.getStoragePath(leaseDOSBidType, name: "findLease")
		let leaseDOSBidCap= account.getCapability<&FindLeaseMarketDirectOfferSoft.MarketBidCollection{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath) 
		if !leaseDOSBidCap.check() {
			account.save<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOSBidStoragePath)
			account.link<&FindLeaseMarketDirectOfferSoft.MarketBidCollection{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath, target: leaseDOSBidStoragePath)
		}

		self.bidsReference= account.borrow<&FindLeaseMarketDirectOfferSoft.MarketBidCollection>(from: leaseDOSBidStoragePath)

	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(name:leaseName, amount: amount, vaultType: self.ftVaultType, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
	}
}