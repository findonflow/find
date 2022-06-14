import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(owner: Address, name: String) {
	prepare(account: AuthAccount) {
		let leaseCollection = getAccount(owner).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		let leaseRef = leaseCollection.borrow() ?? panic("Cannot borrow reference to lease collection reference")
		leaseRef.fulfillAuction(name)

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!
		if profile.getFindName() == name {
			profile.setFindName("")
		}
	}
}
