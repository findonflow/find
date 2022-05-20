import FIND from "../contracts/FIND.cdc"

transaction(names: [String]) {
	prepare(account: AuthAccount) {
		let bids = account.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)!
		for name in names {
			bids.cancelBid(name)
		}
	}
}
