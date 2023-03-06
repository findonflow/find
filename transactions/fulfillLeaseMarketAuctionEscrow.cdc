import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(leaseName: String, amount:UFix64) {

	let bidsReference: &FindLeaseMarketAuctionEscrow.MarketBidCollection

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketAuctionEscrow.MarketBidCollection>())

		self.bidsReference= account.borrow<&FindLeaseMarketAuctionEscrow.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")
	}


	execute {
		self.bidsReference.fulfillAuction(leaseName)
	}

}

