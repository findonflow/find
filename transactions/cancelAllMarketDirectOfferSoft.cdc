import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"

transaction() {

	let saleItems : &FindMarketDirectOfferSoft.SaleItemCollection?

	prepare(account: AuthAccount) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>()))

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
