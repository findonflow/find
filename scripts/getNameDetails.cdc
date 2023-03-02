import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import FindRelatedAccounts from "../contracts/FindRelatedAccounts.cdc"

pub struct FINDReport {
	pub let profile:Profile.UserReport?
	pub let bids: [FIND.BidInfo]
	pub let relatedAccounts: { String: [Address]}
	pub let leases: [LeaseInformation]
	pub let privateMode: Bool
	pub let activatedAccount: Bool


	init(profile: Profile.UserReport?, relatedAccounts: { String: [Address]}, bids: [FIND.BidInfo], leases : [LeaseInformation], privateMode: Bool, activatedAccount: Bool ) {
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
	pub let leaseStatus: LeaseInformation?
	pub let userReport: FINDReport?

	init(status: String, cost: UFix64, leaseStatus: LeaseInformation?, userReport: FINDReport? ) {
		self.status=status
		self.cost=cost
		self.leaseStatus=leaseStatus
		self.userReport=userReport
	}
}

pub fun main(user: String) : NameReport? {

	var findReport: FINDReport? = nil
	var nameLease: LeaseInformation? = nil
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

			let find= FindMarket.getFindTenantAddress()
			let inputLeases = leaseCap.borrow()?.getLeaseInformation() ?? []
			let outputLeases : [LeaseInformation] = []
			for l in inputLeases {
				let leaseInfo = LeaseInformation(l)
				if let sale = FindLeaseMarket.getSaleInformation(tenant: find, name: l.name, marketOption: "FindLeaseMarketSale", getLeaseInfo: false) {
					leaseInfo.addSale(sale)
				}
				if let auctionSoft = FindLeaseMarket.getSaleInformation(tenant: find, name: l.name, marketOption: "FindLeaseMarketAuctionSoft", getLeaseInfo: false) {
					leaseInfo.addSale(auctionSoft)
				}
				outputLeases.append(leaseInfo)
			}

			findReport = FINDReport(
				profile: profileReport,
				relatedAccounts: FindRelatedAccounts.findRelatedFlowAccounts(address:address),
				bids: bidCap.borrow()?.getBids() ?? [],
				leases: outputLeases,
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

	pub struct LeaseInformation {
		pub var name: String
		pub var address: Address
		pub var cost: UFix64
		pub var status: String
		pub var validUntil: UFix64
		pub var lockedUntil: UFix64
		pub var latestBid: UFix64?
		pub var auctionEnds: UFix64?
		pub var salePrice: UFix64?
		pub var latestBidBy: Address?
		pub var currentTime: UFix64
		pub var auctionStartPrice: UFix64?
		pub var auctionReservePrice: UFix64?
		pub var extensionOnLateBid: UFix64?
		pub var addons: [String]

		init(_ l: FIND.LeaseInformation){

			self.name=l.name
			self.status=l.status
			self.validUntil=l.validUntil
			self.lockedUntil=l.lockedUntil
			self.latestBid=l.latestBid
			self.latestBidBy=l.latestBidBy
			self.auctionEnds=l.auctionEnds
			self.salePrice=l.salePrice
			self.currentTime=l.currentTime
			self.auctionStartPrice=l.auctionStartPrice
			self.auctionReservePrice=l.auctionReservePrice
			self.extensionOnLateBid=l.extensionOnLateBid
			self.address=l.address
			self.cost=l.cost
			self.addons=l.addons

		}

		pub fun addSale(_ s: FindLeaseMarket.SaleItemInformation) {
			self.salePrice = s.amount
		}

		pub fun addAuction(_ s: FindLeaseMarket.SaleItemInformation) {
			self.latestBid = s.amount
			self.auctionEnds = s.auction?.auctionEndsAt
			self.latestBidBy = s.bidder
			self.auctionStartPrice = s.auction?.startPrice
			self.auctionReservePrice = s.auction?.reservePrice
			self.extensionOnLateBid = s.auction?.extentionOnLateBid
		}

	}
