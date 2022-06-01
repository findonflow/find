import FindMarket from "../contracts/FindMarket.cdc" 
import FindViews from "../contracts/FindViews.cdc" 
import FIND from "../contracts/FIND.cdc" 
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

pub fun main() : {String : [String] } {
	let result : {String : [String] } = {}

	let findAddress=FindMarket.getFindTenantAddress()
	let tenantCap = FindMarket.getTenantCapability(findAddress)!
	let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up.")
	let marketTypes = FindMarket.getSaleItemTypes()
	for marketType in marketTypes {
		let list : [String] = []
		for type in FindMarket.getBlockedNFT(marketType: marketType) {
			list.append(type.identifier)
		}
		result[FindMarket.getMarketOptionFromType(marketType)] = list
	}

return result
}

pub fun getNFTDetail(pointer: FindViews.ViewReadPointer, views: [String]) : NFTDetail? {

	if !pointer.valid() {
		return nil
	}

	let viewTypes = pointer.getViews() 
	var nftViews: {String : AnyStruct} = {}
	for viewType in viewTypes {
		if views.contains(getType(viewType)) {
			if let view = pointer.resolveView(viewType) {
				nftViews[getType(viewType)] = view! 
			}
		}
	}
	return NFTDetail(pointer, views: nftViews)


}

/* Helper Function */
pub fun getType(_ type: Type) : String {
	let identifier = type.identifier
	var dots = 0
	var counter = 0 
	while counter < identifier.length {
		if identifier[counter] == "." {
			dots = dots + 1
			if dots == 3 {
				break
			}
		}
		counter = counter + 1
	}
	if dots == 0 {
		return identifier
	}
	if counter + 1 > identifier.length {
		panic("Identifier is ".concat(identifier))
	}
	return identifier.slice(from: counter + 1, upTo: identifier.length)
}

//TODO: fix this so that we do not use gas
pub fun resolveRoyalties(_ pointer: FindViews.ViewReadPointer) : [Royalties] {
	let viewTypes = pointer.getViews() 
	var resolveType = Type<MetadataViews.Royalty>()
	if viewTypes.contains(resolveType) {
		let royalty = pointer.resolveView(resolveType)! as! MetadataViews.Royalty
		let address = royalty.receiver.address
		return [Royalties(royaltyName: royalty.description, address: address, findName: FIND.reverseLookup(address), cut: royalty.cut)]
	}
	resolveType = Type<MetadataViews.Royalties>()
	if viewTypes.contains(resolveType) {
		let royalties = pointer.resolveView(resolveType)! as! MetadataViews.Royalties
		let array : [Royalties] = []
		for royalty in royalties.getRoyalties() {
			let address = royalty.receiver.address
			array.append(Royalties(royaltyName: royalty.description, address: address, findName: FIND.reverseLookup(address), cut: royalty.cut))
		}
		return array
	}

	return []
}

pub fun createListingTypeReport(_ allowedListing: FindMarket.AllowedListing) : ListingTypeReport {
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
