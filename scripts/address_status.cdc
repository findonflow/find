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
	pub let itemsForSale: {String : FindMarket.SaleItemCollectionReport}
	pub let marketBids: {String : FindMarket.BidItemCollectionReport}


	init(profile: Profile.UserProfile?, relatedAccounts: {String: Address}, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation], privateMode: Bool, itemsForSale: {String : FindMarket.SaleItemCollectionReport}, marketBids: {String : FindMarket.BidItemCollectionReport}) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
	}
}

//TODO; name_status should reflect this one once they are done. And we should inline this into a contract to avoid duplication
pub fun main(user: Address) : FINDReport {
	let account=getAccount(user)
	let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
	let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()


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
				items[identifier] = report 
				continue
			} 
			if report.ghosts.length > 0 {
				listingTypeIdentifier = report.ghosts[0].listingTypeIdentifier
				let identifier=listingTypeIdentifier.slice(from: 19, upTo: listingTypeIdentifier.length-9)
				items[identifier] = report 
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

	return FINDReport(
		profile: profile?.asProfile(),
		relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:user),
		bids: bidCap.borrow()?.getBids() ?? [],
		leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
		privateMode: profile?.isPrivateModeEnabled() ?? false,
		itemsForSale: items,
		marketBids: marketBids,
	)
}


