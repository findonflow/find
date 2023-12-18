import Profile from "../contracts/Profile.cdc"

transaction(mode: Bool) {

	let profile : &Profile.User?

	prepare(acct: auth(BorrowValue)  AuthAccountAccount) {
		self.profile =acct.borrow<&Profile.User>(from:Profile.storagePath)
	}

	pre{
		self.profile != nil : "Cannot borrow reference to profile"
	}

	execute{
		self.profile!.setPrivateMode(mode)
		self.profile!.emitUpdatedEvent()
	}
}

