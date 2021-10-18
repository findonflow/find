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

	let status=FIND.status(name)
	let cost=FIND.calculateCost(name)
	if let address=status.owner {
		let account=getAccount(address)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		let profile= account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
		var lease:FIND.LeaseInformation?=nil
		if leaseCap.check() {
			lease=leaseCap.borrow()!.getLease(name)
		}
		return FINDNameReport(
			status: lease?.status ?? "taken",
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
