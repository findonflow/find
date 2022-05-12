import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

pub struct FINDNameReport{
	pub let profile:Profile.UserProfile?
	pub let lease: FIND.LeaseInformation?
	pub let status: String
	pub let cost: UFix64
	pub let leases: [FIND.LeaseInformation]
	pub let itemsForSale: {String : FindMarket.SaleItemCollectionReport}
	pub let marketBids: {String : FindMarket.BidItemCollectionReport}


	init(status: String, profile: Profile.UserProfile?, lease : FIND.LeaseInformation?,  cost: UFix64, leases: [FIND.LeaseInformation]
	,itemsForSale: {String : FindMarket.SaleItemCollectionReport}, marketBids: {String : FindMarket.BidItemCollectionReport}) {
		self.status=status
		self.profile=profile
		self.lease=lease
		self.cost=cost
		self.leases=leases
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
	}
}

pub fun main(name: String) : FINDNameReport{

	let status=FIND.status(name)
	let cost=FIND.calculateCost(name)
	if let user=status.owner {
		let account=getAccount(user)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		let items : {String : FindMarket.SaleItemCollectionReport} =  FindMarketOptions.getFindSaleItemReport(address: user)
	
		let marketBids : {String : FindMarket.BidItemCollectionReport} = FindMarketOptions.getFindBidsReport(address: user)

		let profile= account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
		var lease:FIND.LeaseInformation?=nil
		if leaseCap.check() {
			lease=leaseCap.borrow()!.getLease(name)
		}
		return FINDNameReport(
			status: lease?.status ?? "taken",
			profile: profile?.asProfile(),
			lease: lease,
			cost:  cost,
			leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
			itemsForSale: items,
			marketBids:marketBids
		)

	}

	var statusValue= "FREE"
	if  status.status == FIND.LeaseStatus.TAKEN {
		statusValue="NO_PROFILE"
	}
	return FINDNameReport(
		status: statusValue,
		profile: nil, 
		lease: nil,
		cost: cost,
		leases: [],
		itemsForSale: {},
		marketBids: {}
	)
}
 