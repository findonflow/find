import FiNS from "../contracts/FiNS.cdc"

//Check the status of a fin user
pub fun main(tag: String, user: Address) : FiNS.LeaseInformation {
	  let leaseCollection = getAccount(user).getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)
		return leaseCollection.borrow()!.getLease(tag)!
}
