import "FindMarket"
import "FindMarketDirectOfferEscrow"

transaction(ids: [UInt64]) {

	let saleItems : &FindMarketDirectOfferEscrow.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}
}
