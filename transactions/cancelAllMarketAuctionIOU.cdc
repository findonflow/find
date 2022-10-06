import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionIOU from "../contracts/FindMarketAuctionIOU.cdc"

transaction(marketplace:Address) {

	let saleItems : &FindMarketAuctionIOU.SaleItemCollection?

	prepare(account: AuthAccount) {
		let tenant = FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketAuctionIOU.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionIOU.SaleItemCollection>()))

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
