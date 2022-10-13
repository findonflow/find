import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(dapperAddress: Address, leaseName: String, amount: UFix64) {

	let saleItemsCap: Capability<&FindLeaseMarketAuctionSoft.SaleItemCollection{FindLeaseMarketAuctionSoft.SaleItemCollectionPublic}> 
	let bidsReference: &FindLeaseMarketAuctionSoft.MarketBidCollection?
	let ftVaultType: Type

	prepare(account: AuthAccount) {

		let resolveAddress = FIND.resolve(leaseName)
		if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(leaseName))}
		let address = resolveAddress!

		let leaseMarketplace = FindMarket.getTenantAddress("findLease")!
		let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
		let leaseTenant = leaseTenantCapability.borrow()!

		self.saleItemsCap= FindLeaseMarketAuctionSoft.getSaleItemCapability(marketplace:leaseMarketplace, user:address) ?? panic("cannot find sale item cap")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>())

		let item = FindLeaseMarket.assertOperationValid(tenant: leaseMarketplace, name: leaseName, marketOption: marketOption)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
		
		self.ftVaultType = ft.type

		let bidStoragePath=leaseTenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())

		self.bidsReference= account.borrow<&FindLeaseMarketAuctionSoft.MarketBidCollection>(from: bidStoragePath)
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.bid(name:leaseName, amount: amount, vaultType: self.ftVaultType, bidExtraField: {})
	}
}
