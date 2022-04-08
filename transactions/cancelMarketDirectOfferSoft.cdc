import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"

transaction(id: UInt64) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getFindTenant() 
		let saleItems= account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>())!)!
		saleItems.cancel(id)
	}
}
