import FiNS from "../contracts/FiNS.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FiNS.LeaseInformation] {

	  let leaseCollection = getAccount(user).getCapability<&{FiNS.LeaseCollectionPublic}>(FiNS.LeasePublicPath)
		return leaseCollection.borrow()!.getLeaseInformation()
}
