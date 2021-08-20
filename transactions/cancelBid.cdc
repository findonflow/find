import FIN from "../contracts/FIN.cdc"

transaction(tag: String) {
	prepare(account: AuthAccount) {
		let bids = account.borrow<&FIN.BidCollection>(from: FIN.BidStoragePath)!
		bids.cancelBid(tag)
	}
}
