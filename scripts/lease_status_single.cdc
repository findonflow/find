import FIND from "../contracts/FIND.cdc"

//Check the status of a fin user
pub fun main(name: String, user: Address) : FIND.LeaseInformation {
	  let leaseCollection = getAccount(user).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		return leaseCollection.borrow()!.getLease(name)!
}
