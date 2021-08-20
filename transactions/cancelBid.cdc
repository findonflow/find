import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String) {
	prepare(account: AuthAccount) {
		let bids = account.borrow<&FiNS.BidCollection>(from: FiNS.BidStoragePath)!
		bids.cancelBid(tag)
	}
}
