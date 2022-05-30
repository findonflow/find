import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address) {
	prepare(account: AuthAccount) {
		// Get all the saleItems Id

		let tenant = FindMarket.getTenant(marketplace)
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItem>())
		let cap = FindMarket.getSaleItemCollectionCapability(tenantRef: tenant, marketOption: marketOption, address: account.address)
		let ref = cap.borrow() ?? panic("Cannot borrow reference to the capability.")

		let listingType=Type<@FindMarketSale.SaleItemCollection>()
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(listingType))!
		let ids = ref.getIds()
		for id in ids {
			saleItems.delist(id)
		}
	}
}
