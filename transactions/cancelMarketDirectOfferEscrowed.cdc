import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

transaction(marketplace:Address, ids: [UInt64]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketOptions.getTenant(marketplace)
		let saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))!
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
