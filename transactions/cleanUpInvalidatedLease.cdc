import FIND from "../contracts/FIND.cdc"


transaction(names: [String]) {

	let col : &FIND.LeaseCollection

	prepare(acct: AuthAccount) {
		self.col= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("You do not have a profile set up, initialize the user first")
	}

	execute {
		for name in names {
			self.col.cleanUpInvalidatedLease(name)
		}
	}
}
