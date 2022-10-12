import FindMarketAuctionIOUEscrowed from "../contracts/FindMarketAuctionIOUEscrowed.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64) {

	let bidsReference : &FindMarketAuctionIOUEscrowed.MarketBidCollection

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionIOUEscrowed.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketAuctionIOUEscrowed.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow reference to bid collection.")
	}

	execute{
		self.bidsReference.fulfillAuction(id: id, vault: nil)
	}
}
