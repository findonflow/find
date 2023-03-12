import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"

transaction(leaseNames: [String]) {
	let bidsReference: &FindLeaseMarketDirectOfferEscrow.MarketBidCollection?

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath)
	}

	pre{
		self.bidsReference != nil : "Bid resource does not exist"
	}

	execute {
		for n in leaseNames {
			self.bidsReference!.cancelBid(n)
		}
	}
}

