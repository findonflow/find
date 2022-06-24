import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction(marketplace:Address) {
	prepare(account: AuthAccount) {
		let tenant = FindMarket.getTenant(marketplace)
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionSoft.SaleItem>())
		let cap = FindMarket.getSaleItemCollectionCapability(tenantRef: tenant, marketOption: marketOption, address: account.address)
		let ref = cap.borrow() ?? panic("Cannot borrow reference to the capability.")

		let saleItems= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))!
		let ids = ref.getIds()
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
