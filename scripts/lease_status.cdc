import FIND from "../contracts/FIND.cdc"

//Check the status of a fin user
pub fun main(user: Address) : [FIND.LeaseInformation] {

	  let leaseCap = getAccount(user).getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if let leaseCollection= leaseCap.borrow() {
			return leaseCollection.getLeaseInformation()
		}
		return []
}
