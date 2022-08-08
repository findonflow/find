import FindMarket from "../contracts/FindMarket.cdc" 
import FindViews from "../contracts/FindViews.cdc" 
import FIND from "../contracts/FIND.cdc" 
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
//import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

pub struct NFTDetailReport {
	pub let findMarket: {String : FindMarket.SaleItemInformation}
	pub let storefront: StorefrontListing?
	pub let nftDetail: NFTDetail?
	pub let allowedListingActions: {String : ListingTypeReport}

	init(findMarket:{String : FindMarket.SaleItemInformation}, storefront: StorefrontListing?, nftDetail: NFTDetail?, allowedListingActions: {String : ListingTypeReport}) {
		self.findMarket=findMarket
		self.storefront=storefront
		self.nftDetail=nftDetail
		self.allowedListingActions=allowedListingActions
	}
}


pub struct ListingTypeReport {
	pub let ftAlias: [String] 
	pub let ftIdentifiers: [String]
	pub let listingType: String 
	pub let status: String 
	pub let ListingDetails: [ListingRoyalties]

	init(listingType: String, ftAlias: [String], ftIdentifiers: [String],  status: String , ListingDetails: [ListingRoyalties]) {
		self.listingType=listingType 
		self.status=status
		self.ListingDetails=ListingDetails
		self.ftAlias=ftAlias 
		self.ftIdentifiers=ftIdentifiers
	}
}

pub struct NFTDetail {
	pub let id: UInt64 
	pub let uuid: UInt64 
	pub let name:String
	pub let thumbnail:String
	pub let type: String
	pub var rarity:String?
	// pub var royalties: [Royalties]
	pub var editionNumber: UInt64? 
	pub var totalInEdition: UInt64?
	pub var scalars : {String: UFix64}
	pub var tags : {String: String}
	pub var media : {String: String} //url to mediaType
	pub var collectionName: String? 
	pub var collectionDescription: String? 
	pub var data: {String : AnyStruct?}
	pub var views :[String]

	init(_ pointer: FindViews.ViewReadPointer, views: {String : AnyStruct}, resolvedViews: [Type]){

		let item = pointer.getViewResolver()

		let nftInfo = FindMarket.NFTInfo(item, id:pointer.id, detail: true)

		self.scalars=nftInfo.scalars
		self.tags=nftInfo.tags
		self.rarity=nftInfo.rarity
		self.media={}
		self.collectionName=nil
		self.collectionDescription=nil

		if let grouping=MetadataViews.getNFTCollectionDisplay(item) {
			self.collectionName=grouping.name
			self.collectionDescription=grouping.description
		}

		/* Medias */
		if let medias=MetadataViews.getMedias(item) {
			for m in medias.items {
				let url = m.file.uri() 
				let type = m.mediaType
				self.media[url] = type
			}
		}

		let display = MetadataViews.getDisplay(item) ?? panic("Could not find display")
		self.name=display.name
		self.thumbnail=display.thumbnail.uri()
		self.type=item.getType().identifier
		self.id=pointer.id
		self.uuid=pointer.getUUID()

		/* Edition */
		self.editionNumber=nftInfo.editionNumber
		self.totalInEdition=nftInfo.totalInEdition

		/* Royalties */
		// self.royalties=resolveRoyalties(pointer)

		self.views=[]
		for view in item.getViews() {
			if ignoreViews().contains(view) {
				continue
			}
			if resolvedViews.contains(view) {
				continue
			}
			self.views.append(view.identifier)
		}
		self.data=views

	}
}


pub struct StoreFrontCut {

	pub let amount:UFix64
	pub let address: Address
	pub let findName:String?

	init(amount:UFix64, address:Address){
		self.amount=amount
		self.address=address
		self.findName= reverseLookup(address)
	}
}

pub struct ListingRoyalties {

	pub let ftAlias: String?
	pub let ftIdentifier: String
	pub let royalties: [Royalties]

	init(ftAlias: String?, ftIdentifier: String, royalties: [Royalties]) {
		self.ftAlias=ftAlias 
		self.ftIdentifier=ftIdentifier
		self.royalties=royalties 
	}
}

pub struct Royalties {

	pub let royaltyName: String 
	pub let address: Address 
	pub let findName: String? 
	pub let cut: UFix64 

	init(royaltyName: String , address: Address, findName: String?, cut: UFix64) {
		self.royaltyName=royaltyName 
		self.address=address 
		self.findName=findName 
		self.cut=cut
	}
}


pub struct StorefrontListing {
	pub let foo:String

	init() {

		self.foo ="bar"
	}
}
/*
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
*/

pub var counter = 0

pub fun main(user: String, project:String, id: UInt64, views: [String]) : NFTDetailReport?{
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {
		return nil
	}
	let address = resolveAddress!

	let account = getAuthAccount(address) 
	let storagePath = getStoragePath(project)
	let publicPath = PublicPath(identifier: "find_temp_path_".concat(counter.toString()))!
	counter = counter + 1
	account.link<&{MetadataViews.ResolverCollection}>(publicPath, target: storagePath)
	let cap = account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
	if !cap.check() {
		panic("The user does not set up collection correctly.")
	}
	let pointer = FindViews.ViewReadPointer(cap: cap, id: id)

	let nftDetail = getNFTDetail(pointer:pointer, views: views)
	if nftDetail == nil {
		return nil
	}


	let findAddress=FindMarket.getFindTenantAddress()
	let findMarket=FindMarket.getNFTListing(tenant:findAddress, address: address, id: nftDetail!.uuid, getNFTInfo:false)

	/*
	var listings : StorefrontListing? = nil
	let storefrontCap = account.getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)

	if storefrontCap.check() {
		let storefrontRef=storefrontCap.borrow()!
		for listingId in storefrontRef.getListingIDs() {
			let listing = storefrontRef.borrowListing(listingResourceID: listingId)!
			let nft=listing.borrowNFT()
			if nft.id==id && !listing.getDetails().purchased {
				listings = StorefrontListing(listingId: listingId, details: listing.getDetails())
			}
		}
	}
	*/

	let tenantCap = FindMarket.getTenantCapability(findAddress)!
	let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up. Tenant : ".concat(tenantCap.address.toString()))

	let marketTypes = FindMarket.getSaleItemTypes()
	var report : {String : ListingTypeReport} = {}
	for marketType in marketTypes {
		if let allowedListing = tenantRef.getAllowedListings(nftType: pointer.getItemType(), marketType: marketType) {
			report[FindMarket.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing, pointer: pointer, tenantRef: tenantRef)
		}
	}

	return NFTDetailReport(findMarket:findMarket, storefront:nil, nftDetail: nftDetail, allowedListingActions: report)

}

pub let resolvedAddresses : {Address : String} = {}

pub var nftRoyalties : [Royalties]? = nil

pub fun reverseLookup(_ addr: Address) : String? {

	if let name = resolvedAddresses[addr] {
		if name == "" {
			return nil
		} else {
			return name
		}
	}
	let name = FIND.reverseLookup(addr) 
	if name == nil {
		resolvedAddresses[addr] = ""
	} else {
		resolvedAddresses[addr] = name
	}
	return name

}

pub fun getNFTDetail(pointer: FindViews.ViewReadPointer, views: [String]) : NFTDetail? {

	if !pointer.valid() {
		return nil
	}

	let viewTypes = pointer.getViews() 
	var nftViews: {String : AnyStruct} = {}
	var resolvedViews: [Type] = []
	for viewType in viewTypes {
		if views.contains(viewType.identifier) {
			if let view = pointer.resolveView(viewType) {
				nftViews[viewType.identifier] = view! 
				resolvedViews.append(viewType)
			}
		}
	}
	return NFTDetail(pointer, views: nftViews, resolvedViews: resolvedViews)


}

/* Helper Function */
pub fun resolveRoyalties(_ pointer: FindViews.ViewReadPointer) : [Royalties] {
	let array : [Royalties] = []
	for royalty in pointer.getRoyalty().getRoyalties() {
		let address = royalty.receiver.address
		array.append(Royalties(royaltyName: royalty.description, address: address, findName: reverseLookup(address), cut: royalty.cut))
	}

	return array
}

pub fun resolveFindRoyalties(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, listing: Type, nft: Type, ft: Type) : [Royalties] {

	let cuts = tenantRef.getTenantCut(name:"", listingType: listing, nftType:nft, ftType:ft)

	let royalties :[Royalties] = []
	if cuts.findCut != nil {
		royalties.append(Royalties(royaltyName: cuts.findCut!.description, address: cuts.findCut!.receiver.address, findName: reverseLookup(cuts.findCut!.receiver.address), cut: cuts.findCut!.cut))
	}

	if cuts.tenantCut != nil {
		royalties.append(Royalties(royaltyName: cuts.tenantCut!.description, address: cuts.tenantCut!.receiver.address, findName: reverseLookup(cuts.tenantCut!.receiver.address), cut: cuts.tenantCut!.cut))
	}
	
	return royalties
}

pub fun createListingTypeReport(_ allowedListing: FindMarket.AllowedListing, pointer: FindViews.ViewReadPointer, tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}) : ListingTypeReport {
	let listingType = allowedListing.listingType.identifier
	var ftAlias : [String] = []
	var ftIdentifier : [String] = []
	var listingDetails : [ListingRoyalties] = []
	for ft in allowedListing.ftTypes {
		ftIdentifier.append(ft.identifier)
		var alias : String? = nil
		if let ftInfo = FTRegistry.getFTInfo(ft.identifier) {
			alias = ftInfo.alias
			ftAlias.append(ftInfo.alias)
		}

		// getRoyalties 
		var nftR = nftRoyalties 
		if nftR == nil {
			nftRoyalties = resolveRoyalties(pointer)
			nftR = nftRoyalties
		}

		let findR = resolveFindRoyalties(tenantRef: tenantRef, listing: allowedListing.listingType , nft: pointer.getItemType(), ft: ft)
		findR.appendAll(nftR!)

		listingDetails.append(ListingRoyalties(ftAlias: alias, ftIdentifier: ft.identifier, royalties: findR))
	}
	
	return ListingTypeReport(listingType: listingType, ftAlias: ftAlias, ftIdentifiers: ftIdentifier,  status: allowedListing.status , ListingDetails: listingDetails)
}

pub fun ignoreViews() : [Type] {
	return [
	Type<MetadataViews.NFTCollectionDisplay>() , 
	Type<MetadataViews.Medias>() ,
	Type<MetadataViews.Display>() ,
	Type<MetadataViews.Edition>() ,
	Type<MetadataViews.Editions>() , 
	Type<MetadataViews.Media>()  

	]
}

pub fun getStoragePath(_ nftIdentifier: String) : StoragePath {
	if let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys {
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
		return collection.collectionData.storagePath
	}

	if let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier :nftIdentifier) {
		return collection.collectionData.storagePath
	}
	panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
}
