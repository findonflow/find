import FindMarket from "../contracts/FindMarket.cdc"

transaction(owner: Address, id: UInt64) {
	prepare(account: AuthAccount) {
		FindMarket.getFindSaleItemCapability(owner)!.borrow()!.fulfillAuction(id)
	}
}
