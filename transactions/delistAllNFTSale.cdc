import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction() {

	let saleItems : auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant = FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		let ids = self.saleItems!.getIds()
		for id in ids {
			self.saleItems!.delist(id)
		}
	}
}
