import "FindMarket"
import "FindMarketDirectOfferEscrow"

transaction(id: UInt64) {
	let bidsReference: auth(FindMarketDirectOfferEscrow.Buyer) &FindMarketDirectOfferEscrow.MarketBidCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<auth(FindMarketDirectOfferEscrow.Buyer) &FindMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath)
	}

	pre{
		self.bidsReference != nil : "This account does not have a bid collection"
	}

	execute {
		self.bidsReference!.cancelBid(id)
	}

}

