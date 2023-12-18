import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

transaction() {

	let saleItems : &FindMarketDirectOfferEscrow.SaleItemCollection?

	prepare(account: AuthAccount) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))

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
