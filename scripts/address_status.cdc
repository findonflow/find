import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import RelatedAccounts from "../contracts/RelatedAccounts.cdc"

pub struct FINDReport{
	pub let profile:Profile.UserProfile?
	pub let bids: [FIND.BidInfo]
	pub let relatedAccounts: { String: Address}
	pub let leases: [FIND.LeaseInformation]
	pub let privateMode: Bool

	init(profile: Profile.UserProfile?, relatedAccounts: {String: Address}, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation], privateMode: Bool) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
	}
}

pub fun main(user: Address) : FINDReport{

	let account=getAccount(user)
	let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)

	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
	let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
	return FINDReport(
		profile: profile?.asProfile(),
		relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:user),
		bids: bidCap.borrow()?.getBids() ?? [],
		leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
		privateMode: profile?.isPrivateModeEnabled() ?? false
	)

}
