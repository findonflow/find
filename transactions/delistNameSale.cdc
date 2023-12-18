import FIND from "../contracts/FIND.cdc"

transaction(names: [String]) {

	let finLeases : &FIND.LeaseCollection?

	prepare(acct: auth(BorrowValue)  AuthAccountAccount) {
		self.finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
	}

	pre{
		self.finLeases != nil : "Cannot borrow reference to find lease collection"
	}

	execute{
		for name in names {
			self.finLeases!.delistSale(name)
		}
	}
}
