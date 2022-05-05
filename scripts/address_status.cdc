import FIND from "../contracts/FIND.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import Profile from "../contracts/Profile.cdc"
import RelatedAccounts from "../contracts/RelatedAccounts.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"


pub struct FINDReport{
	pub let profile:Profile.UserProfile?
	pub let bids: [FIND.BidInfo]
	pub let relatedAccounts: { String: Address}
	pub let leases: [FIND.LeaseInformation]
	pub let privateMode: Bool
	pub let itemsForSale: [FindMarket.SaleInformation]
	pub let marketBids: [FindMarket.BidInfo]
	pub let ghosts:  [FindMarket.GhostListing]

	init(profile: Profile.UserProfile?, relatedAccounts: {String: Address}, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation], privateMode: Bool, itemsForSale: [FindMarket.SaleInformation], marketBids: [FindMarket.BidInfo], ghosts:[FindMarket.GhostListing]) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
		self.ghosts=ghosts
	}
}

//TODO; name_status should reflect this one once they are done. And we should inline this into a contract to avoid duplication
pub fun main(user: Address) : FINDReport {
	let account=getAccount(user)
	let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
	let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()


	//Bam:will this work?
	let caps : [&{FindMarket.SaleItemCollectionPublic}]= []

	if let sale =FindMarketSale.getFindSaleItemCapability(user)!.borrow() {
		caps.append(sale)
	}


	let items : [FindMarket.SaleInformation] = []
	let ghosts: [FindMarket.GhostListing] = []
	for cap in caps {
		let report=caps[cap].getReport()
		items.appendAll(report.items)
		items.appendAll(report.ghost)
	}

	//TODO: I think we should make this a little more efficient, now we are looping twice
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

	//TOOD: do we need ghost bids aswell?

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

	return FINDReport(
		profile: profile?.asProfile(),
		relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:user),
		bids: bidCap.borrow()?.getBids() ?? [],
		leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
		privateMode: profile?.isPrivateModeEnabled() ?? false,
		itemsForSale: items,
		marketBids: bids,
		ghosts: ghosts
	)
}
