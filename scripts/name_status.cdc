import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

pub struct FINDNameReport{
	pub let profile:Profile.UserProfile?
	pub let lease: FIND.LeaseInformation?
	pub let address:Address?
	pub let status: String
	pub let cost: UFix64

	init(status: String, profile: Profile.UserProfile?, lease : FIND.LeaseInformation?, address: Address?, cost: UFix64) {
		self.status=status
		self.profile=profile
		self.lease=lease
		self.address=address
		self.cost=cost
	}
}

//Check the status of a fin user
pub fun main(name: String) : FINDNameReport{
	let cost=FIND.calculateCost(name)
	let profile= FIND.lookup(name)

	if let address=profile?.owner?.address {
		let account=getAccount(address)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		var lease:FIND.LeaseInformation?=nil

		if leaseCap.check() {
			lease=leaseCap.borrow()!.getLease(name)

		}
	  return FINDNameReport(
			status: "taken",
		 profile: profile?.asProfile(),
		 lease: lease,
		 address:address,
		 cost:  cost
	 )

	}

	return FINDNameReport(
		status: "free",
		profile: nil, 
		lease: nil,
		address:nil,
		cost: cost
	)

}
