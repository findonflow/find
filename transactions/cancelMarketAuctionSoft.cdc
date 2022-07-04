import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction(marketplace:Address, ids: [UInt64]) {

	let saleItems : &FindMarketAuctionSoft.SaleItemCollection?

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionSoft.SaleItemCollection>()))
	}

	pre{
		self.saleItems != nil 
	}

	execute{
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}

}
