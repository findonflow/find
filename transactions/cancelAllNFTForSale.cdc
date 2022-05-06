import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

transaction() {
	prepare(account: AuthAccount) {
		// Get all the saleItems Id

		let items = FindMarketSale.getFindSaleItemCapability(account.address)!.borrow()!.getSaleItemReport()

		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let listingType=Type<@FindMarketSale.SaleItemCollection>()
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(listingType))!
		let listingItems = items.items
		for item in listingItems {
			saleItems.delist(item.listingId)
		}
		let ghosts = items.ghosts
		for ghost in ghosts {
			saleItems.delist(ghost.id)
		}	


	}
}
