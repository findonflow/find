import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(aliasOrIdentifier: String) : {String : ListingTypeReport} {
	let tenantCap = FindMarketTenant.getFindTenantCapability()
	let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up.")

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