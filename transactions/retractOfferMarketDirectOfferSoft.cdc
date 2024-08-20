import "FindMarket"
import "FindMarketDirectOfferSoft"

transaction(id: UInt64) {
	let bidsReference: auth(FindMarketDirectOfferSoft.Buyer) &FindMarketDirectOfferSoft.MarketBidCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<auth(FindMarketDirectOfferSoft.Buyer) &FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath)
	}

	pre{
		self.bidsReference != nil : "Bid resource does not exist"
	}

	execute {
		self.bidsReference!.cancelBid(id)
	}
}

