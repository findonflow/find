import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

transaction(marketplace:Address) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferEscrow.SaleItem>())
		let cap = FindMarket.getSaleItemCollectionCapability(tenantRef: tenant, marketOption: marketOption, address: account.address)
		let ref = cap.borrow() ?? panic("Cannot borrow reference to the capability.")

		let saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))!
		let ids = saleItems.getIds()
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
