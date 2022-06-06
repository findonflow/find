import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(marketplace:Address, owner: String, id: UInt64) {
	prepare(account: AuthAccount) {
		let resolveAddress = FIND.resolve(owner)
		if resolveAddress == nil { 
			panic("The address input is not a valid name nor address. Input : ".concat(owner))
		}
		let address = resolveAddress!
		FindMarketAuctionEscrow.getSaleItemCapability(marketplace:marketplace, user:address)!.borrow()!.fulfillAuction(id)
	}
}