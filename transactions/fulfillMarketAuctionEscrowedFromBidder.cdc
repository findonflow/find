import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

transaction(marketplace:Address, id: UInt64) {
	prepare(account: AuthAccount) {
		let tenant=FindMarketOptions.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionEscrow.MarketBidCollection>())!
		let bidsReference= account.borrow<&FindMarketAuctionEscrow.MarketBidCollection>(from: storagePath)!

		bidsReference.fulfillAuction(id)
	}
}
