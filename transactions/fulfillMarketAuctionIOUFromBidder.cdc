import FindMarketAuctionIOU from "../contracts/FindMarketAuctionIOU.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64) {

	let bidsReference : &FindMarketAuctionIOU.MarketBidCollection?

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionIOU.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketAuctionIOU.MarketBidCollection>(from: storagePath)

		
	}

	pre{
		self.bidsReference != nil : "Cannot borrow reference to bid collection."
	}

	execute{
		self.bidsReference!.fulfillAuction(id: id, vault: nil)
	}
}
