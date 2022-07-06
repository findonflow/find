import FIND from "../contracts/FIND.cdc"

transaction(name: String) {

	let finLeases : &FIND.LeaseCollection?

	prepare(account: AuthAccount) {
		self.finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
	}

	pre{
		self.finLeases != nil : "Cannot borrow reference to find lease collection"
	}

	execute{
		self.finLeases!.startAuction(name)
	}
}
