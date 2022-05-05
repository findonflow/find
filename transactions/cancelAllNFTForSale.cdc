import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

transaction() {
	prepare(account: AuthAccount) {
		// Get all the saleItems Id

		let items = FindMarketSale.getFindSaleItemCapability(account.address)!.borrow()!.getItemsForSale()

		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))!

		for item in items {
			saleItems.delist(item.listingId)
		}
		
	}
}
