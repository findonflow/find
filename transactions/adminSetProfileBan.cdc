import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(user: String) {
	prepare(acct: auth(BorrowValue)  AuthAccountAccount) {
		let profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		let address =FIND.resolve(user) ?? panic("Not a registered name or valid address.")
		profile.addBan(address)
	}
}

