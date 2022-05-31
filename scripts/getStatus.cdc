import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"
import RelatedAccounts from "../contracts/RelatedAccounts.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

pub struct FINDReport{
	pub let profile:Profile.UserReport?
	pub let bids: [FIND.BidInfo]
	pub let relatedAccounts: { String: Address}
	pub let leases: [FIND.LeaseInformation]
	pub let privateMode: Bool
	pub let itemsForSale: {String : FindMarket.SaleItemCollectionReport}
	pub let marketBids: {String : FindMarket.BidItemCollectionReport}


	init(profile: Profile.UserReport?, relatedAccounts: {String: Address}, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation], privateMode: Bool, itemsForSale: {String : FindMarket.SaleItemCollectionReport}, marketBids: {String : FindMarket.BidItemCollectionReport}) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
	}
}

pub struct NameReport {
	pub let status: String 
	pub let cost: UFix64 

	init(status: String, cost: UFix64) {
		self.status=status 
		self.cost=cost
	}
}

pub struct Report {
	pub let FINDReport: FINDReport?
	pub let NameReport: NameReport?

	init(FINDReport: FINDReport?, NameReport: NameReport?) {
		self.FINDReport=FINDReport 
		self.NameReport=NameReport
	}
}

pub fun main(user: String) : Report? {

	var findReport: FINDReport? = nil
	if let address=FIND.resolve(user) {
		let account=getAccount(address)
		let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()

		let find= FindMarket.getFindTenantAddress()
		let items : {String : FindMarket.SaleItemCollectionReport} = FindMarket.getSaleItemReport(tenant:find, address: address, getNFTInfo:true)

		let marketBids : {String : FindMarket.BidItemCollectionReport} = FindMarket.getBidsReport(tenant:find, address: address, getNFTInfo:true)

		findReport = FINDReport(
			profile: profile?.asReport(),
			relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:address),
			bids: bidCap.borrow()?.getBids() ?? [],
			leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
			privateMode: profile?.isPrivateModeEnabled() ?? false,
			itemsForSale: items,
			marketBids: marketBids
		)
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
		nameReport = NameReport(status: s, cost: cost)
	}
	

	return Report(FINDReport: findReport, NameReport: nameReport)
}


