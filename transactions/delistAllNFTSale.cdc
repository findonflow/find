import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address) {

	let saleItems : &FindMarketSale.SaleItemCollection?

	prepare(account: AuthAccount) {
		let tenant = FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>())) 
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
