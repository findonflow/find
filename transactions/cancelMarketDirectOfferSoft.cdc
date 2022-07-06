import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"

transaction(marketplace:Address, ids: [UInt64]) {

	let saleItems : &FindMarketDirectOfferSoft.SaleItemCollection?

	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute {
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}
}
