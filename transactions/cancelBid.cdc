import FIND from "../contracts/FIND.cdc"

transaction(tag: String) {
	prepare(account: AuthAccount) {
		let bids = account.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)!
		bids.cancelBid(tag)
	}
}
