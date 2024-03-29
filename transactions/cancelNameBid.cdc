import FIND from "../contracts/FIND.cdc"

transaction(names: [String]) {

	let bids : &FIND.BidCollection?

	prepare(account: AuthAccount) {
		self.bids = account.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)
	}

	pre{
		self.bids != nil : "Cannot borrow reference to find bid collection"
	}

	execute {
		for name in names {
			self.bids!.cancelBid(name)
		}
	}

}
