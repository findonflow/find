import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

// array of [User in string (find name or address)]
transaction(unfollows:[String]) {

	let profile : &Profile.User

	prepare(account: AuthAccount) {

		self.profile =account.borrow<&Profile.User>(from:Profile.storagePath) ?? panic("Cannot borrow reference to profile")

	}

	execute{
		for key in unfollows {
			let user = FIND.resolve(key) ?? panic(key.concat(" cannot be resolved. It is either an invalid .find name or address"))
			self.profile.unfollow(user)
		}
	}
}

