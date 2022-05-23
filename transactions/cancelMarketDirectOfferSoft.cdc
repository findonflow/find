import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"

transaction(marketplace:Address, ids: [UInt64]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketOptions.getTenant(marketplace)
		let saleItems= account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>()))!
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
