import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction(marketplace:Address) {

	let saleItems : &FindMarketAuctionSoft.SaleItemCollection?

	prepare(account: AuthAccount) {
		let tenant = FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to the saleItem."
	}

	execute {
		let ids = self.saleItems!.getIds()
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}
}
