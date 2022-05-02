import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"

transaction(id: UInt64) {
	prepare(account: AuthAccount) {
		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionEscrow.MarketBidCollection>())!
		let bidsReference= account.borrow<&FindMarketAuctionEscrow.MarketBidCollection>(from: storagePath)!

		bidsReference.fulfillAuction(id)
	}
}
