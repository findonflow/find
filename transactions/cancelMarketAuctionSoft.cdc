import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction(ids: [UInt64]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let saleItems= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))!
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
