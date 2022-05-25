import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

transaction(marketplace:Address) {
	prepare(account: AuthAccount) {
		// Get all the saleItems Id

		let tenant = FindMarketOptions.getTenant(marketplace)
		let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketSale.SaleItem>())
		let cap = FindMarketOptions.getSaleItemCollectionCapability(tenantRef: tenant, marketOption: marketOption, address: account.address)
		let ref = cap.borrow() ?? panic("Cannot borrow reference to the capability.")

		let listingType=Type<@FindMarketSale.SaleItemCollection>()
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(listingType))!
		let ids = ref.getIds()
		for id in ids {
			saleItems.delist(id)
		}
	}
}
