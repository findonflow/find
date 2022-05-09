import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"

transaction(owner: Address, id: UInt64) {
	prepare(account: AuthAccount) {
		FindMarketAuctionEscrow.getFindSaleItemCapability(owner)!.borrow()!.fulfillAuction(id)
	}
}
