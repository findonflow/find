import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 
import FIND from "../contracts/FIND.cdc" 
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"

pub struct NFTDetailReport {
	pub let findMarket: {String : FindMarket.SaleItemCollectionReport}

	init(findMarket:{String : FindMarket.SaleItemCollectionReport}, storefront: {UInt64: NFTStorefront.ListingDetails}) {
		self.findMarket=findMarket
	}
}


pub fun main(user: String, id: UInt64) : NFTDetailReport?{

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {
		return nil
	}
	let address = resolveAddress!
	let findMarket=FindMarketOptions.getFindSaleItems(address: address, id: id)

	let account=getAccount(address)
	let listings : {UInt64 : NFTStorefront.ListingDetails} = {}
	let storefrontCap = account.getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)

	if storefrontCap.check() {
		let storefrontRef=storefrontCap.borrow()!
		for listingId in storefrontRef.getListingIDs() {
			let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
			let details=listing.getDetails()
			if details.purchased==true {
				continue
			}
			let nft=listing.borrowNFT()
			if nft.id==id {
				listings[listingId] = listing.getDetails()
			}
		}
	}
	return NFTDetailReport(findMarket:findMarket, storefront: listings)

}

