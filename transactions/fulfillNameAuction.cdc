import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(owner: Address, name: String) {

	let leases : &FIND.LeaseCollection{FIND.LeaseCollectionPublic}?

	prepare(account: AuthAccount) {
		self.leases = getAccount(owner).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath).borrow()
	}

	pre{
		self.leases != nil : "Cannot borrow reference to lease collection reference. Account address: ".concat(owner.toString())
	}

	execute{
		self.leases!.fulfillAuction(name)
	}
}
