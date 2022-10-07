import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferIOU from "../contracts/FindMarketDirectOfferIOU.cdc"

transaction(marketplace:Address, id: UInt64) {
	let bidsReference: &FindMarketDirectOfferIOU.MarketBidCollection? 

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferIOU.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferIOU.MarketBidCollection>(from: storagePath) 
	}

	pre{
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.cancelBid(id)
	}

}

