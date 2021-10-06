import FIND from "../contracts/FIND.cdc"

transaction(name: String, directSellPrice:UFix64, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionMinBidIncrement: UFix64, auctionExtensionOnLateBid: UFix64) {
	prepare(acct: AuthAccount) {
		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.listForSale(name: name,  directSellPrice:directSellPrice, auctionStartPrice: auctionStartPrice, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionMinBidIncrement: auctionMinBidIncrement, auctionExtensionOnLateBid: auctionExtensionOnLateBid)
			

	}
}
