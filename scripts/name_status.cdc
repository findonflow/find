import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"


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


	// Will refine this with a consolidating MarketOption Contract
	let saleCaps : [Capability<&{FindMarket.SaleItemCollectionPublic}>] = [
		FindMarketSale.getFindSaleItemCapability(user)!,
		FindMarketDirectOfferEscrow.getFindSaleItemCapability(user)!,
		FindMarketAuctionEscrow.getFindSaleItemCapability(user)!,
		FindMarketAuctionSoft.getFindSaleItemCapability(user)!,
		FindMarketDirectOfferSoft.getFindSaleItemCapability(user)!
	]


	let items : {String : FindMarket.SaleItemCollectionReport} = {}
	for cap in saleCaps {
		if let ref = cap.borrow() {
			let report=ref.getSaleItemReport()
			var listingTypeIdentifier: String = ""
			if report.items.length > 0 {
				listingTypeIdentifier = report.items[0].listingTypeIdentifier
				let identifier=listingTypeIdentifier.slice(from: 19, upTo: listingTypeIdentifier.length-9)
				continue
			} 
			if report.ghosts.length > 0 {
				listingTypeIdentifier = report.ghosts[0].listingTypeIdentifier
				let identifier=listingTypeIdentifier.slice(from: 19, upTo: listingTypeIdentifier.length-9)
				items[listingTypeIdentifier] = report 
			}
		}
	}

	// Will refine this with a consolidating MarketOption Contract
	let bidsaps : [Capability<&{FindMarket.MarketBidCollectionPublic}>] = [
		FindMarketDirectOfferEscrow.getFindBidCapability(user)!,
		FindMarketDirectOfferSoft.getFindBidCapability(user)!,
		FindMarketAuctionSoft.getFindBidCapability(user)!,
		FindMarketAuctionEscrow.getFindBidCapability(user)!
	]


	let marketBids : {String : FindMarket.BidItemCollectionReport} = {}
	for cap in bidsaps {
		if let ref = cap.borrow() {
			let report=ref.getBidsReport()
			var listingTypeIdentifier: String = ""
			if report.items.length > 0 {
				listingTypeIdentifier = report.items[0].bidTypeIdentifier
				let identifier=listingTypeIdentifier.slice(from: 19, upTo: listingTypeIdentifier.length-4)
				marketBids[identifier] = report 
				continue
			} 
			if report.ghosts.length > 0 {
				listingTypeIdentifier = report.ghosts[0].listingTypeIdentifier
				let identifier=listingTypeIdentifier.slice(from: 19, upTo: listingTypeIdentifier.length-4)
				marketBids[identifier] = report 
			}
		}
	}
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
