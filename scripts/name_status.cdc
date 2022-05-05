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

	//BAM: is this the right way?
	//pub let marketOptions : { String: MarketOptionReport}
	/*
	 - items
	 - ghotsItems
	 - bids
	 - ghostBids
	 */
	pub let itemsForSale: [FindMarket.SaleItemInformation]
	pub let marketBids: [FindMarket.BidInfo]
	pub let ghosts: [FindMarket.GhostListing]

	init(status: String, profile: Profile.UserProfile?, lease : FIND.LeaseInformation?,  cost: UFix64, leases: [FIND.LeaseInformation]
	,itemsForSale: [FindMarket.SaleItemInformation], marketBids: [FindMarket.BidInfo], ghosts: [FindMarket.GhostListing]) {
		self.status=status
		self.profile=profile
		self.lease=lease
		self.cost=cost
		self.leases=leases
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
		self.ghosts=ghosts
	}
}

pub fun main(name: String) : FINDNameReport{

	let status=FIND.status(name)
	let cost=FIND.calculateCost(name)
	if let user=status.owner {
		let account=getAccount(user)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

	let items : [FindMarket.SaleInformation] = []
	let ghosts: [FindMarket.GhostListing] = []
	if let sale =FindMarketSale.getFindSaleItemCapability(user)!.borrow() {
		items.appendAll(sale.getItemsForSaleWithSaleInformationStruct())
		ghosts.appendAll(sale.getGhostListings())
	}

	if let doe=FindMarketDirectOfferEscrow.getFindSaleItemCapability(user)!.borrow() {
		items.appendAll(doe.getItemsForSaleWithSaleInformationStruct())
		ghosts.appendAll(doe.getGhostListings())
	}

	if let ae = FindMarketAuctionEscrow.getFindSaleItemCapability(user)!.borrow() {
		items.appendAll(ae.getItemsForSaleWithSaleInformationStruct())
		ghosts.appendAll(ae.getGhostListings())
	}

	if let as = FindMarketAuctionSoft.getFindSaleItemCapability(user)!.borrow() {
		items.appendAll(as.getItemsForSaleWithSaleInformationStruct())
		ghosts.appendAll(as.getGhostListings())
	}

	if let dos = FindMarketDirectOfferSoft.getFindSaleItemCapability(user)!.borrow() {
		items.appendAll(dos.getItemsForSaleWithSaleInformationStruct())
		ghosts.appendAll(dos.getGhostListings())
	}


		let bids : [FindMarket.BidInfo] = []
	if let bDoe= FindMarketDirectOfferEscrow.getFindBidCapability(user)!.borrow() {
		bids.appendAll(bDoe.getBids())
		ghosts.appendAll(bDoe.getGhostListings())
	}

	if let bDos= FindMarketDirectOfferSoft.getFindBidCapability(user)!.borrow() {
		bids.appendAll(bDos.getBids())
		ghosts.appendAll(bDos.getGhostListings())
	}

	if let bAs= FindMarketAuctionSoft.getFindBidCapability(user)!.borrow() {
		bids.appendAll(bAs.getBids())
		ghosts.appendAll(bAs.getGhostListings())
	}

	if let bAe= FindMarketAuctionEscrow.getFindBidCapability(user)!.borrow() {
		bids.appendAll(bAe.getBids())
		ghosts.appendAll(bAe.getGhostListings())
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
			marketBids:bids,
			ghosts:ghosts
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
		ghosts:[]
	)
}
