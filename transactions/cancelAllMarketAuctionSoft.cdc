import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction() {

	let saleItems : &FindMarketAuctionSoft.SaleItemCollection?

	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
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
