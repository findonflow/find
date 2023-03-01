import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"

transaction(ids: [UInt64]) {

	let saleItems : &FindMarketAuctionSoft.SaleItemCollection?

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
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
