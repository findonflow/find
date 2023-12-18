import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(name: String) {

	let finLeases : &FIND.LeaseCollection?

	prepare(account: auth(BorrowValue) &Account) {
		self.finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) 
	}

	pre{
		self.finLeases != nil : "Cannot borrow reference to find lease collection"
	}

	execute{
		self.finLeases!.fulfill(name)
	}
}
