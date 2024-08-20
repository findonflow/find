import "Profile"

transaction(mode: Bool) {

	let profile : &Profile.User?

	prepare(acct: auth(BorrowValue) &Account) {
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

