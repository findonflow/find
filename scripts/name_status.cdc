import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Profile from "../contracts/Profile.cdc"

pub struct FINDNameReport{
	pub let profile:Profile.UserProfile?
	pub let lease: FIND.LeaseInformation?
	pub let status: String
	pub let cost: UFix64
	pub let leases: [FIND.LeaseInformation]
	pub let itemsForSale: [FindMarket.SaleItemInformation]
	pub let marketBids: [FindMarket.BidInfo]

	init(status: String, profile: Profile.UserProfile?, lease : FIND.LeaseInformation?,  cost: UFix64, leases: [FIND.LeaseInformation]
,itemsForSale: [FindMarket.SaleItemInformation], marketBids: [FindMarket.BidInfo]) {
		self.status=status
		self.profile=profile
		self.lease=lease
		self.cost=cost
		self.leases=leases
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
	}
}

//Check the status of a fin user
pub fun main(name: String) : FINDNameReport{

	let status=FIND.status(name)
	let cost=FIND.calculateCost(name)
	if let address=status.owner {
		let account=getAccount(address)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)


		let marketBidCap= account.getCapability<&FindMarket.MarketBidCollection{FindMarket.MarketBidCollectionPublic}>(FindMarket.MarketBidCollectionPublicPath)
		let saleItemCap= account.getCapability<&FindMarket.SaleItemCollection{FindMarket.SaleItemCollectionPublic}>(FindMarket.SaleItemCollectionPublicPath)
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
			itemsForSale: saleItemCap.borrow()?.getItemsForSale() ?? [],
			marketBids:marketBidCap.borrow()?.getBids() ?? []
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
		itemsForSale: [],
		marketBids: [],
	)

}
