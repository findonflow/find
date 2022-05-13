import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String) {
	prepare(acct: AuthAccount) {

		let leaseCollectionOwner = acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		if !leaseCollectionOwner.check() {
			panic("Not a find user")
		}

		if leaseCollectionOwner.borrow()!.getLease(name) == nil {
			panic("You do not own this lease so you cannot set it as main name")
		}

		let profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		profile.setFindName(name)
		profile.emitUpdatedEvent()
	}
}

