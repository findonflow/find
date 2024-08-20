import "FIND"

transaction(names: [String]) {

	let finLeases : auth(FIND.AuctionOwner, FIND.LeaseOwner) &FIND.LeaseCollection?

	prepare(account: auth(BorrowValue) &Account) {
		self.finLeases= account.storage.borrow<auth(FIND.AuctionOwner, FIND.LeaseOwner) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
	}

	pre{
		self.finLeases != nil : "Cannot borrow reference to find leases collection"
	}

	execute {
		for name in names {
			self.finLeases!.cancel(name)
			self.finLeases!.delistAuction(name)
		}
	}
}
