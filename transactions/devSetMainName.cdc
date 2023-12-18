import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String) {
	prepare(acct: auth(BorrowValue)  AuthAccountAccount) {


		let profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		profile.setFindName(name)
	}
}

