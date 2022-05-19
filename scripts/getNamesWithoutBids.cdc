import FIND from "../contracts/FIND.cdc"


pub fun main(user: String) : [String] {

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return []}
	let address = resolveAddress!
	let account=getAccount(address)
	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

	let leases=leaseCap.borrow()?.getLeaseInformation() ?? []

	var leasesWithBids :[String] =[]
	for lease in leases {
		if lease.latestBidBy == nil {
			leasesWithBids.append(lease.name)
		}
	}

	return leasesWithBids
}
