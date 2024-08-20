import "FindMarket"
import "FindMarketDirectOfferEscrow"

transaction() {

	let saleItems : auth(FindMarketDirectOfferEscrow.Seller) &FindMarketDirectOfferEscrow.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<auth(FindMarketDirectOfferEscrow.Seller) &FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))

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
