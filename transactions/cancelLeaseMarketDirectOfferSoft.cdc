import "FindMarket"
import "FindLeaseMarketDirectOfferSoft"

transaction(leaseNames: [String]) {

	let saleItems : auth(FindLeaseMarketDirectOfferSoft.Seller) &FindLeaseMarketDirectOfferSoft.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<auth(FindLeaseMarketDirectOfferSoft.Seller) &FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute {
		for leaseName in leaseNames {
			self.saleItems!.cancel(leaseName)
		}
	}
}
