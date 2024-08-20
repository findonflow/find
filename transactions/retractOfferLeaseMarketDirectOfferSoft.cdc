import "FindMarket"
import "FindLeaseMarketDirectOfferSoft"

transaction(leaseName: String) {
	let bidsReference: auth(FindLeaseMarketDirectOfferSoft.Buyer) &FindLeaseMarketDirectOfferSoft.MarketBidCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<auth(FindLeaseMarketDirectOfferSoft.Buyer) &FindLeaseMarketDirectOfferSoft.MarketBidCollection>(from: storagePath)
	}

	pre{
		self.bidsReference != nil : "Bid resource does not exist"
	}

	execute {
		self.bidsReference!.cancelBid(leaseName)
	}
}

