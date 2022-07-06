import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"

transaction(marketplace:Address, ids: [UInt64]) {

	let saleItems : &FindMarketAuctionEscrow.SaleItemCollection?

	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionEscrow.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		for id in ids {
			self.saleItems!.cancel(id)
		}
	}
}
