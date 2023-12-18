import FIND from "../contracts/FIND.cdc"

transaction(names: [String]) {

	let finLeases : &FIND.LeaseCollection?

	prepare(account: auth(BorrowValue) &Account) {
		self.finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
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
