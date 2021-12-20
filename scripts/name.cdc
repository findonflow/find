import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"


//Check the status of a fin user
pub fun main(address: Address) : String?{

	let account=getAccount(address)
	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

	if !leaseCap.check() {
		return nil
	}

	let profile= Profile.find(address).asProfile()
	let leases = leaseCap.borrow()!.getLeaseInformation() 
	var time : UFix64?= nil
	var name :String?= nil
	for lease in leases {

		//filter out all leases that are FREE or LOCKED since they are not actice
		if lease.status != "TAKEN" {
			continue
		}

		//if we have not set a 
		if profile.findName == "" {
			if time == nil || lease.validUntil < time! {
				time=lease.validUntil
				name=lease.name
			}
		}

		if profile.findName == lease.name {
			return lease.name
		}
	}
	return name
}
