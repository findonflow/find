import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

pub struct FINDReport{
	pub let profile:Profile.UserProfile?
	pub let bids: [FIND.BidInfo]
	pub let leases: [FIND.LeaseInformation]

	init(profile: Profile.UserProfile?, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation]) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
	}
}

//Check the status of a fin user
pub fun main(user: Address) : FINDReport{

	let account=getAccount(user)
	let bidCap = account.getCapability<&{FIND.BidCollectionPublic}>(FIND.BidPublicPath)

	 let leaseCap = account.getCapability<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

	 return FINDReport(
		 profile: account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()?.asProfile(),
		 bids: bidCap.borrow()?.getBids() ?? [],
		 leases: leaseCap.borrow()?.getLeaseInformation() ?? []
	 )

}
