import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferIOU from "../contracts/FindMarketDirectOfferIOU.cdc"

transaction(marketplace:Address) {

	let saleItems : &FindMarketDirectOfferIOU.SaleItemCollection?

	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketDirectOfferIOU.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferIOU.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem."
	}

	execute{
		let ids = self.saleItems!.getIds()
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}

}
