import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(name: String) {
	prepare(account: AuthAccount) {

		let finLeases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		finLeases.fulfill(name)

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!
		if profile.getFindName() == name {
			profile.setFindName("")
		}
	}
}
