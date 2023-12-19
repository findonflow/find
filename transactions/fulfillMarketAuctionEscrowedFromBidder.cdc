import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(id: UInt64) {

	let bidsReference : &FindMarketAuctionEscrow.MarketBidCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionEscrow.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<&FindMarketAuctionEscrow.MarketBidCollection>(from: storagePath)


	}

	pre{
		self.bidsReference != nil : "Cannot borrow reference to bid collection."
	}

	execute{
		self.bidsReference!.fulfillAuction(id)
	}
}
