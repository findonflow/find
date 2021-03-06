import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

transaction(marketplace:Address, id: UInt64) {
	let bidsReference: &FindMarketDirectOfferEscrow.MarketBidCollection? 

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath) 
	}

	pre{
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.cancelBid(id)
	}

}

