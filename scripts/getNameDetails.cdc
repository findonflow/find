import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import RelatedAccounts from "../contracts/RelatedAccounts.cdc"

pub struct FINDReport {
	pub let profile:Profile.UserReport?
	pub let bids: [FIND.BidInfo]
	pub let relatedAccounts: { String: Address}
	pub let leases: [FIND.LeaseInformation]
	pub let privateMode: Bool
	pub let activatedAccount: Bool 


	init(profile: Profile.UserReport?, relatedAccounts: {String: Address}, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation], privateMode: Bool, activatedAccount: Bool ) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.activatedAccount=activatedAccount
	}
}

pub struct NameReport {
	pub let status: String
	pub let cost: UFix64 
	pub let leaseStatus: FIND.LeaseInformation?
	pub let userReport: FINDReport? 

	init(status: String, cost: UFix64, leaseStatus: FIND.LeaseInformation?, userReport: FINDReport? ) {
		self.status=status 
		self.cost=cost 
		self.leaseStatus=leaseStatus
		self.userReport=userReport
	}
}

pub fun main(user: String) : NameReport? {

	var findReport: FINDReport? = nil
	var nameLease: FIND.LeaseInformation? = nil
	if let address=FIND.resolve(user) {
		let account=getAccount(address)
		if account.balance != 0.0 {
			let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
			let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
			let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()

			var profileReport = profile?.asReport() 
			if profileReport != nil && profileReport!.findName != FIND.reverseLookup(address) {
				profileReport = Profile.UserReport(
					findName: "",
					address: profileReport!.address,
					name: profileReport!.name,
					gender: profileReport!.gender,
					description: profileReport!.description,
					tags: profileReport!.tags,
					avatar: profileReport!.avatar,
					links: profileReport!.links,
					wallets: profileReport!.wallets, 
					following: profileReport!.following,
					followers: profileReport!.followers,
					allowStoringFollowers: profileReport!.allowStoringFollowers,
					createdAt: profileReport!.createdAt
				)
			}

			findReport = FINDReport(
				profile: profileReport,
				relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:address),
				bids: bidCap.borrow()?.getBids() ?? [],
				leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
				privateMode: profile?.isPrivateModeEnabled() ?? false, 
				activatedAccount: true
			)
			if FIND.validateFindName(user) && findReport != nil {
				for lease in findReport!.leases {
					if lease.name == user {
						nameLease = lease
						break
					}
				}
			}
		} else {
			findReport = FINDReport(
				profile: nil,
				relatedAccounts: {},
				bids: [],
				leases: [],
				privateMode: false, 
				activatedAccount: false
			)
		}
		
	}

	var nameReport : NameReport? = nil 
	if FIND.validateFindName(user) {
		let status = FIND.status(user)
		let cost=FIND.calculateCost(user)
		var s="TAKEN"	
		if status.status == FIND.LeaseStatus.FREE {
			s="FREE"
		} else if status.status == FIND.LeaseStatus.LOCKED {
			s="LOCKED"
		}
		nameReport = NameReport(status: s, cost: cost, leaseStatus: nameLease, userReport: findReport)
	}
	

	return nameReport
}


