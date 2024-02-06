import "FindMarket"
import "FindLeaseMarketDirectOfferSoft"

transaction() {

	let saleItems : &FindLeaseMarketDirectOfferSoft.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem."
	}

	execute{
		let nameLeases = self.saleItems!.getNameSales()
		for nameLease in nameLeases {
			self.saleItems!.cancel(nameLease)
		}
	}

}
