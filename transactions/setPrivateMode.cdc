import Profile from "../contracts/Profile.cdc"

transaction(mode: Bool) {
	prepare(acct: AuthAccount) {
		let profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		profile.setPrivateMode(mode)
		profile.emitUpdatedEvent()
	}
}

