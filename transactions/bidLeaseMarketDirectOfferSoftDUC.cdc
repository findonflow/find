import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(dapperAddress: Address, leaseName: String, amount: UFix64, validUntil: UFix64?) {

	let bidsReference: &FindLeaseMarketDirectOfferSoft.MarketBidCollection?
	let ftVaultType: Type

	prepare(account: AuthAccount) {
		
		let ft = FTRegistry.getFTInfo(Type<@DapperUtilityCoin.Vault>().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(Type<@DapperUtilityCoin.Vault>().identifier))

		self.ftVaultType = ft.type

		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!
		let bidStoragePath=leaseTenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindLeaseMarketDirectOfferSoft.MarketBidCollection>(from: bidStoragePath)

	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(name:leaseName, amount: amount, vaultType: self.ftVaultType, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
	}
}
