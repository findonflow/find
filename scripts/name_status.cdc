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

pub fun main(name: String) : FINDNameReport{

	let status=FIND.status(name)
	let cost=FIND.calculateCost(name)
	if let user=status.owner {
		let account=getAccount(user)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)


		let items : [FindMarket.SaleItemInformation] = []
		if let sale =FindMarketSale.getFindSaleItemCapability(user)!.borrow() {
			items.appendAll(sale.getItemsForSale())
		}

		if let doe=FindMarketDirectOfferEscrow.getFindSaleItemCapability(user)!.borrow() {
			items.appendAll(doe.getItemsForSale())
		}

		if let ae = FindMarketAuctionEscrow.getFindSaleItemCapability(user)!.borrow() {
			items.appendAll(ae.getItemsForSale())
		}

		if let as = FindMarketAuctionSoft.getFindSaleItemCapability(user)!.borrow() {
			items.appendAll(as.getItemsForSale())
		}

		if let dos = FindMarketDirectOfferSoft.getFindSaleItemCapability(user)!.borrow() {
			items.appendAll(dos.getItemsForSale())
		}


		let bids : [FindMarket.BidInfo] = []
		if let bDoe= FindMarketDirectOfferEscrow.getFindBidCapability(user)!.borrow() {
			bids.appendAll(bDoe.getBids())
		}

		if let bDos= FindMarketDirectOfferSoft.getFindBidCapability(user)!.borrow() {
			bids.appendAll(bDos.getBids())
		}

		if let bAs= FindMarketAuctionSoft.getFindBidCapability(user)!.borrow() {
			bids.appendAll(bAs.getBids())
		}

		if let bAe= FindMarketAuctionEscrow.getFindBidCapability(user)!.borrow() {
			bids.appendAll(bAe.getBids())
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
			marketBids:bids
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
