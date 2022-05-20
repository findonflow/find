import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(owner: String, id: UInt64) {
	prepare(account: AuthAccount) {
		let resolveAddress = FIND.resolve(owner)
		if resolveAddress == nil { 
			panic("The address input is not a valid name nor address. Input : ".concat(owner))
		}
		let address = resolveAddress!
		FindMarketAuctionEscrow.getFindSaleItemCapability(address)!.borrow()!.fulfillAuction(id)
	}
}
