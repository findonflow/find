import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionIOUDapper from "../contracts/FindMarketAuctionIOUDapper.cdc"

transaction(marketplace:Address) {

	let saleItems : &FindMarketAuctionIOUDapper.SaleItemCollection?

	prepare(account: AuthAccount) {
		let tenant = FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketAuctionIOUDapper.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionIOUDapper.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to the saleItem capability."
	}

	execute {
		let ids = self.saleItems!.getIds()
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}
}
