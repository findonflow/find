import FIND from "../contracts/FIND.cdc"

access(all) main(user: String) : [FIND.LeaseInformation] {

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return []}
	let address = resolveAddress!
	let account=getAccount(address)

	if account.balance == 0.0 {
		return []
	}

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
