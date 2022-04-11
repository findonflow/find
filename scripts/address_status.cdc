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
	pub let itemsForSale: [FindMarket.SaleItemInformation]
	pub let marketBids: [FindMarket.BidInfo]

	init(profile: Profile.UserProfile?, relatedAccounts: {String: Address}, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation], privateMode: Bool, itemsForSale: [FindMarket.SaleItemInformation], marketBids: [FindMarket.BidInfo]) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
	}
}

pub fun main(user: Address) : FINDReport {
	let account=getAccount(user)
	let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
	let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()

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

	return FINDReport(
		profile: profile?.asProfile(),
		relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:user),
		bids: bidCap.borrow()?.getBids() ?? [],
		leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
		privateMode: profile?.isPrivateModeEnabled() ?? false,
		itemsForSale: items,
		marketBids: bids,
	)
}
