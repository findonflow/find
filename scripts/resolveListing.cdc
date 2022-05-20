import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 
import FIND from "../contracts/FIND.cdc" 
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"

pub struct NFTDetailReport {
	pub let findMarket: {String : FindMarket.SaleItemCollectionReport}
	pub let storefront: StorefrontReport?

	init(findMarket:{String : FindMarket.SaleItemCollectionReport}, storefront: StorefrontReport?) {
		self.findMarket=findMarket
		self.storefront=storefront
	}
}

pub struct StoreFrontCut {

	pub let amount:UFix64
	pub let address: Address
	pub let findName:String?

	init(amount:UFix64, address:Address){
		self.amount=amount
		self.address=address
		self.findName= FIND.reverseLookup(address)
	}
}

pub struct StorefrontListing {
	pub let nftID:UInt64
	pub let nftIdentifier: String
	pub let saleCut: [StoreFrontCut]
	pub let amount:UFix64
	pub let ftTypeIdentifier:String
	pub let storefront:UInt64
	pub let listingID:UInt64

	init(listingId:UInt64, details: NFTStorefront.ListingDetails) {

		self.saleCut=[]
		self.nftID=details.nftID
		self.nftIdentifier=details.nftType.identifier
		for cutDetails in details.saleCuts {
			self.saleCut.append(StoreFrontCut(amount:cutDetails.amount, address:cutDetails.receiver.address))
		}
		self.amount=details.salePrice
		self.ftTypeIdentifier=details.salePaymentVaultType.identifier
		self.storefront=details.storefrontID
		self.listingID=listingId
	}
}


/*

*/
pub struct StorefrontReport {

	pub let items : [StorefrontListing]
	pub let ghosts: [StorefrontListing]

	init(_ listings : {UInt64 : NFTStorefront.ListingDetails}) {

		self.items=[]
		self.ghosts=[]
		for key in listings.keys {

			let details = listings[key]!

			let listing = StorefrontListing(listingId: key, details:details)

			//Here we really have no way to find out if this is truly a ghost or not since the state in storefront only change 
			//to purchased if it is bought in storefront. And we have no way to get a capability and check if it is present either
			if details.purchased {
				self.ghosts.append(listing)
			} else {
				self.items.append(listing)
			}
		}
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
			let nft=listing.borrowNFT()
			if nft.id==id {
				listings[listingId] = listing.getDetails()
			}
		}
	}

	var storefrontReport:StorefrontReport?=nil
	if listings.length != 0 {
		storefrontReport=StorefrontReport(listings)
	}
	return NFTDetailReport(findMarket:findMarket, storefront: storefrontReport)

}

