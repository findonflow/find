import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

//Remove one or more listings from a marketplace
transaction(marketplace:Address, ids: [UInt64]) {

	let saleItems : &FindMarketSale.SaleItemCollection?

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
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
