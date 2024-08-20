import "Profile"
import "FIND"


transaction(name: String) {

	let leaseCollectionOwner : Capability<&FIND.LeaseCollection>
	let profile : &Profile.User

	prepare(acct: auth(BorrowValue) &Account) {
		self.leaseCollectionOwner = acct.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)!
		if (self.leaseCollectionOwner.borrow()!.getLease(name) == nil) {
			panic("You do not own this lease so you cannot set it as main name")
		}
		self.profile =acct.storage.borrow<&Profile.User>(from:Profile.storagePath)!
	}

	pre{
		self.leaseCollectionOwner.check() : "Not a find user"
	}

	execute{
		self.profile.setFindName(name)
	}
}

