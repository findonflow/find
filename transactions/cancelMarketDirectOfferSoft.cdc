import "FindMarket"
import "FindMarketDirectOfferSoft"

transaction(ids: [UInt64]) {

	let saleItems : auth(FindMarketDirectOfferSoft.Seller) &FindMarketDirectOfferSoft.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<auth(FindMarketDirectOfferSoft.Seller) &FindMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.SaleItemCollection>()))

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
