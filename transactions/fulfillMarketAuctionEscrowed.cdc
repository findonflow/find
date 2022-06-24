import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(marketplace:Address, owner: String, id: UInt64) {
	prepare(account: AuthAccount) {
		let resolveAddress = FIND.resolve(owner)
		if resolveAddress == nil { 
			panic("The address input is not a valid name nor address. Input : ".concat(owner))
		}
		let address = resolveAddress!
		let saleItem = FindMarketAuctionEscrow.getSaleItemCapability(marketplace:marketplace, user:address)?.borrow() 
		if saleItem == nil || saleItem! == nil {
			panic("Cannot get reference to the sale item. Sale item ID: ".concat(id.toString()))
		}
		saleItem!!.fulfillAuction(id)
	}
}
