import Profile from "../contracts/Profile.cdc"


transaction(avatar: String) {
	prepare(acct: AuthAccount) {
		let profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		profile.setAvatar(avatar)

		profile.emitUpdatedEvent()
	}
}

