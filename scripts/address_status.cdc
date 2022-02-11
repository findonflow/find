import FIND from "../contracts/FIND.cdc"
import Market from "../contracts/Market.cdc"
import Profile from "../contracts/Profile.cdc"
import RelatedAccounts from "../contracts/RelatedAccounts.cdc"

pub struct FINDReport{
	pub let profile:Profile.UserProfile?
	pub let bids: [FIND.BidInfo]
	pub let relatedAccounts: { String: Address}
	pub let leases: [FIND.LeaseInformation]
	pub let privateMode: Bool
	pub let itemsForSale: [Market.SaleItemInformation]
	pub let marketBids: [Market.BidInfo]

	init(profile: Profile.UserProfile?, relatedAccounts: {String: Address}, bids: [FIND.BidInfo], leases : [FIND.LeaseInformation], privateMode: Bool, itemsForSale: [Market.SaleItemInformation], marketBids: [Market.BidInfo]) {
		self.profile=profile
		self.bids=bids
		self.leases=leases
		self.relatedAccounts=relatedAccounts
		self.privateMode=privateMode
		self.itemsForSale=itemsForSale
		self.marketBids=marketBids
	}
}

//Check the status of a fin user
pub fun main(user: Address) : FINDReport{

	let account=getAccount(user)
	let bidCap = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
	let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
	let marketBidCap= account.getCapability<&Market.MarketBidCollection{Market.MarketBidCollectionPublic}>(Market.MarketBidCollectionPublicPath)
	let saleItemCap= account.getCapability<&Market.SaleItemCollection{Market.SaleItemCollectionPublic}>(Market.SaleItemCollectionPublicPath)
	let profile=account.getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
	return FINDReport(
		profile: profile?.asProfile(),
		relatedAccounts: RelatedAccounts.findRelatedFlowAccounts(address:user),
		bids: bidCap.borrow()?.getBids() ?? [],
		leases: leaseCap.borrow()?.getLeaseInformation() ?? [],
		privateMode: profile?.isPrivateModeEnabled() ?? false,
		itemsForSale: saleItemCap.borrow()?.getItemsForSale() ?? [],
		marketBids:marketBidCap.borrow()?.getBids() ?? []
	)

}
