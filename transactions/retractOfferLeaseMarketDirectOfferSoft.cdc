import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(leaseName: String) {
	let bidsReference: &FindLeaseMarketDirectOfferSoft.MarketBidCollection?

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindLeaseMarketDirectOfferSoft.MarketBidCollection>(from: storagePath)
	}

	pre{
		self.bidsReference != nil : "Bid resource does not exist"
	}

	execute {
		self.bidsReference!.cancelBid(leaseName)
	}
}

