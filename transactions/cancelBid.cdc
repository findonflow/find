import FIND from "../contracts/FIND.cdc"

transaction(name: String) {
	prepare(account: AuthAccount) {
		let bids = account.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)!
		bids.cancelBid(name)
	}
}
