import "FindMarket"
import "FindMarketSale"

//Remove one or more listings from a marketplace
transaction(ids: [UInt64]) {

	let saleItems : auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		for id in ids {
			self.saleItems!.delist(id)
		}
	}
}
