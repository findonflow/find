import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

// map of {User in string (find name or address) : [tag]}
transaction(follows:{String : [String]}) {

	let profile : &Profile.User

	prepare(account: auth(BorrowValue) &Account) {

		self.profile =account.storage.borrow<&Profile.User>(from:Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection!.check() {
			account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)

		}
	}

	execute{
		for key in follows.keys {
			let user = FIND.resolve(key) ?? panic(key.concat(" cannot be resolved. It is either an invalid .find name or address"))
			let tags = follows[key]!
			self.profile.follow(user, tags: tags)
		}
	}
}

