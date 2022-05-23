import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(aliasOrIdentifier: String) : {String : ListingTypeReport} {
	let tenantCap = FindMarketTenant.getFindTenantCapability()
	let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up.")

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

pub fun main(marketplace:Address, user: String, id: UInt64) : NFTDetailReport?{
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {
		return nil
	}
	let address = resolveAddress!
	let findMarket=FindMarketOptions.getSaleItems(tenant: marketplace, address: address, id: id)

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

	let nftInfo = NFTRegistry.getNFTInfo(aliasOrIdentifier) ?? panic("This NFT is not supported by the registry.")
	let marketTypes = FindMarketOptions.getSaleItemTypes()
	var report : {String : ListingTypeReport} = {}
	for marketType in marketTypes {
		if let allowedListing = tenantRef.getAllowedListings(nftType: nftInfo.type, marketType: marketType) {
			report[FindMarketOptions.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing)
		}
	}

	return report
}


pub struct ListingTypeReport {
	pub let listingType: String 
	pub let ftAlias: [String] 
	pub let ftIdentifiers: [String] 
	pub let status: String 

	init(listingType: String, ftAlias: [String], ftIdentifiers: [String],  status: String ) {
		self.listingType=listingType 
		self.ftAlias=ftAlias 
		self.ftIdentifiers=ftIdentifiers 
		self.status=status
	}
}

pub fun createListingTypeReport(_ allowedListing: FindMarketTenant.AllowedListing) : ListingTypeReport {
	let listingType = allowedListing.listingType.identifier
	var ftAlias : [String] = []
	var ftIdentifier : [String] = []
	for ft in allowedListing.ftTypes {
		ftIdentifier.append(ft.identifier)
		if let ftInfo = FTRegistry.getFTInfo(ft.identifier) {
			ftAlias.append(ftInfo.alias)
		}
	}
	return ListingTypeReport(listingType: listingType, ftAlias: ftAlias, ftIdentifiers: ftIdentifier,  status: allowedListing.status )
}
