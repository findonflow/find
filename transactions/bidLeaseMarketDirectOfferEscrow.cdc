import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"

transaction(leaseName: String, ftAliasOrIdentifier:String, amount: UFix64, validUntil: UFix64?) {

	let bidsReference: &FindLeaseMarketDirectOfferEscrow.MarketBidCollection?
	let ftVault: @FungibleToken.Vault

	prepare(account: AuthAccount) {

		let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

		self.ftVault <- account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)?.withdraw(amount: amount) ?? panic("Cannot borrow vault from buyer")

		let leaseMarketplace = FindMarket.getFindTenantAddress()
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		let leaseDOSBidType= Type<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>()
		let leaseDOSBidPublicPath=leaseTenant.getPublicPath(leaseDOSBidType)
		let leaseDOSBidStoragePath= leaseTenant.getStoragePath(leaseDOSBidType)
		let leaseDOSBidCap= account.getCapability<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection{FindLeaseMarketDirectOfferEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath)
		if !leaseDOSBidCap.check() {
			account.save<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>(<- FindLeaseMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOSBidStoragePath)
			account.link<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection{FindLeaseMarketDirectOfferEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath, target: leaseDOSBidStoragePath)
		}

		self.bidsReference= account.borrow<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection>(from: leaseDOSBidStoragePath)

	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(name:leaseName, vault: <- self.ftVault, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
	}
}
