import FindMarket from "../contracts/FindMarket.cdc" 
import FindViews from "../contracts/FindViews.cdc" 
import FIND from "../contracts/FIND.cdc" 
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
//import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
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

pub struct NFTDetail {
	pub let id: UInt64 
	pub let uuid: UInt64 
	pub let name:String
	pub let thumbnail:String
	pub let type: String
	pub var rarity:String?
	pub var royalties: [Royalties]
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

		self.scalars={}
		self.tags={}
		self.media={}
		self.collectionName=nil
		self.collectionDescription=nil

		if let grouping=MetadataViews.getNFTCollectionDisplay(item) {
			self.collectionName=grouping.name
			self.collectionDescription=grouping.description
		}

		/* Rarity */
		self.rarity=nil
		if let r = FindViews.getRarity(item) {
			self.rarity=r.rarityName
		}


		if let t= FindViews.getTags(item) {
			self.tags=t.getTag()
		}			

		if let scalar=FindViews.getScalar(item){
			self.scalars=scalar.getScalar()
		}
		/* Medias */
		if let medias=MetadataViews.getMedias(item) {
			for m in medias.items {
				let url = m.file.uri() 
				let type = m.mediaType
				self.media[url] = type
			}
		}

		if let media=FindViews.getMedia(item) {
			let url = media.file.uri() 
			let type = media.mediaType
			self.media[url] = type
		}

		let display = MetadataViews.getDisplay(item) ?? panic("Could not find display")
		self.name=display.name
		self.thumbnail=display.thumbnail.uri()
		self.type=item.getType().identifier
		self.id=pointer.id
		self.uuid=pointer.getUUID()

		/* Edition */
		self.editionNumber=nil
		self.totalInEdition=nil
		if let editions = MetadataViews.getEditions(item) {
			for edition in editions.infoList {
				if edition.name == nil {
					self.editionNumber=edition.number
					self.totalInEdition=edition.max
				} else {
					self.scalars["edition_".concat(edition.name!).concat("_number")] = UFix64(edition.number)
					if edition.max != nil {
						self.scalars["edition_".concat(edition.name!).concat("_max")] = UFix64(edition.max!)
					}
				}
			}
		}

		/* Royalties */
		self.royalties=resolveRoyalties(pointer)

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
		self.findName= FIND.reverseLookup(address)
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

pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {
		return nil
	}
	let address = resolveAddress!

	let account = getAccount(address) 
	let publicPath = NFTRegistry.getNFTInfo(nftAliasOrIdentifier)?.publicPath ?? panic("This NFT is not supported by NFT Registry. Type : ".concat(nftAliasOrIdentifier))
	let cap = account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
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
			report[FindMarket.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing)
		}
	}

	return NFTDetailReport(findMarket:findMarket, storefront:nil, nftDetail: nftDetail, allowedListingActions: report)

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
		array.append(Royalties(royaltyName: royalty.description, address: address, findName: FIND.reverseLookup(address), cut: royalty.cut))
	}

	return array
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

pub fun ignoreViews() : [Type] {
	return [
	Type<MetadataViews.NFTCollectionDisplay>() , 
	Type<FindViews.Rarity>() ,
	Type<FindViews.Tag>() , 
	Type<FindViews.Scalar>() ,
	Type<MetadataViews.Medias>() ,
	Type<MetadataViews.Display>() ,
	Type<MetadataViews.Edition>() ,
	Type<MetadataViews.Editions>() , 
	Type<MetadataViews.Media>()  

	]
}
