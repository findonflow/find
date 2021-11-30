import FIND from "../contracts/FIND.cdc"


//Check the status of a fin user
pub fun main(user: Address) : [FIND.LeaseInformation] {

	let account=getAccount(user)
	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

	let leases=leaseCap.borrow()?.getLeaseInformation() ?? []

	var leasesWithBids :[FIND.LeaseInformation] =[]
	for lease in leases {
		if lease.latestBidBy != nil {
			leasesWithBids.append(lease)
		}
	}

	return leasesWithBids
}
