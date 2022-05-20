import FIND from "../contracts/FIND.cdc"

transaction(owner: Address, name: String) {
	prepare(account: AuthAccount) {
		let leaseCollection = getAccount(owner).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		let leaseRef = leaseCollection.borrow() ?? panic("Cannot borrow reference to lease collection reference")
		leaseRef.fulfillAuction(name)

	}
}
