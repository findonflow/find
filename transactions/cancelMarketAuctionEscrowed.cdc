import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"

transaction(ids: [UInt64]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let saleItems= account.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionEscrow.SaleItemCollection>()))!
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
