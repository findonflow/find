import FindMarketOptions from "../contracts/FindMarketOptions.cdc" 
import FindViews from "../contracts/FindViews.cdc" 
import FindMarket from "../contracts/FindMarket.cdc" 
import FindMarketTenant from "../contracts/FindMarketTenant.cdc" 
import FIND from "../contracts/FIND.cdc" 
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
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
    pub var collectionName: String? 
    pub var collectionDescription: String? 
    pub var views: {String : AnyStruct?}

init(_ pointer: FindViews.ViewReadPointer, views: {String : AnyStruct}){

            let item = pointer.getViewResolver()

			self.scalars={}
			self.tags={}
			/* Scalar */
			self.collectionName=nil
			self.collectionDescription=nil
			if item.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) != nil {
				let view = item.resolveView(Type<MetadataViews.NFTCollectionDisplay>())!
				if view as? MetadataViews.NFTCollectionDisplay != nil {
					let grouping = view as! MetadataViews.NFTCollectionDisplay
					self.collectionName=grouping.name
					self.collectionDescription=grouping.description
				}
			}
			/* Rarity */
			self.rarity=nil
			if item.resolveView(Type<FindViews.Rarity>()) != nil {
				let view = item.resolveView(Type<FindViews.Rarity>())!
				if view as? FindViews.Rarity != nil {
					let rarity = view as! FindViews.Rarity
					self.rarity=rarity.rarityName
				}
			} 
			/* Tag */
			if item.resolveView(Type<FindViews.Tag>()) != nil {
				let view = item.resolveView(Type<FindViews.Tag>())!
				if view as? FindViews.Tag != nil {
					let tags = view as! FindViews.Tag
					self.tags=tags.getTag()
				}
			}
			/* Scalar */
			if item.resolveView(Type<FindViews.Scalar>()) != nil {
				let view = item.resolveView(Type<FindViews.Scalar>())!
				if view as? FindViews.Scalar != nil {
					let scalar = view as! FindViews.Scalar
					self.scalars=scalar.getScalar()
				}
			}
			
			/* NFT Collection Display */
			let display = item.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
			self.name=display.name
			self.thumbnail=display.thumbnail.uri()
			self.type=item.getType().identifier
			self.id=pointer.id
            self.uuid=pointer.getUUID()

			/* Edition */
			self.editionNumber=nil
			self.totalInEdition=nil
			if item.resolveView(Type<FindViews.Edition>()) != nil {
				let view = item.resolveView(Type<FindViews.Edition>())!
				if view as? FindViews.Edition != nil {
					let edition = view as! FindViews.Edition
					self.editionNumber=edition.editionNumber
					self.totalInEdition=edition.totalInEdition
				}
			} 
			/* Royalties */
			self.royalties=resolveRoyalties(pointer)

			self.views=views
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

pub fun main(user: String, nftAliasOrIdentifier:String, id: UInt64, views: [String]) : NFTDetailReport?{
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {
		return nil
	}
	let address = resolveAddress!

	let account = getAccount(address) 
	let publicPath = NFTRegistry.getNFTInfo(nftAliasOrIdentifier)?.publicPath ?? panic("This NFT is not supported by NFT Registry")
 	let cap = account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
	let pointer = FindViews.ViewReadPointer(cap: cap, id: id)

	let nftDetail = getNFTDetail(pointer:pointer, views: views)
	if nftDetail == nil {
		return nil
	}


	let findMarket=FindMarketOptions.getNFTFindListing(address: address, id: nftDetail!.uuid, getNFTInfo:false)

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

	let tenantCap = FindMarketTenant.getFindTenantCapability()
	let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up.")

	let marketTypes = FindMarketOptions.getSaleItemTypes()
	var report : {String : ListingTypeReport} = {}
	for marketType in marketTypes {
		if let allowedListing = tenantRef.getAllowedListings(nftType: pointer.getItemType(), marketType: marketType) {
			report[FindMarketOptions.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing)
		}
	}

	return NFTDetailReport(findMarket:findMarket, storefront: listings, nftDetail: nftDetail, allowedListingActions: report)

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
