import FIND from "../contracts/FIND.cdc"

transaction(name: String, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64) {
	prepare(acct: AuthAccount) {
		let finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.listForAuction(name: name, auctionStartPrice: auctionStartPrice, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration,  auctionExtensionOnLateBid: auctionExtensionOnLateBid)

	}
}
