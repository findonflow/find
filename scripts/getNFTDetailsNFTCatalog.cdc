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
	pub let linkedForMarket : Bool?

	init(findMarket:{String : FindMarket.SaleItemInformation}, storefront: StorefrontListing?, nftDetail: NFTDetail?, allowedListingActions: {String : ListingTypeReport}, linkedForMarket : Bool?) {
		self.findMarket=findMarket
		self.storefront=storefront
		self.nftDetail=nftDetail
		self.allowedListingActions=allowedListingActions
		self.linkedForMarket = linkedForMarket
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
	pub let description:String
	pub let thumbnail:String
	pub let type: String
	pub var externalViewURL: String?
	pub var rarity:MetadataViews.Rarity?
	pub var editions: [MetadataViews.Edition]
	pub var serial: UInt64?
	pub var traits: [MetadataViews.Trait]
	pub var media : {String: String} //url to mediaType
	pub var collection : NFTCollectionDisplay?
	pub var license : String? 
	pub var data: {String : AnyStruct?}
	pub var views :[String]

	init(_ pointer: FindViews.ViewReadPointer, views: {String : AnyStruct}, resolvedViews: [Type]){

		self.type=pointer.itemType.identifier
		self.id=pointer.id
		self.uuid=pointer.getUUID()

		// Display 
		let display = views["Display"] ?? panic("Could not find display")
		let d = display as! MetadataViews.Display
		self.name=d.name
		self.description=d.description
		self.thumbnail=d.thumbnail.uri()
		views.remove(key: "Display")

		// External URL 
		self.externalViewURL = nil 
		if let externalURL = views["ExternalURL"] {
			if let e = externalURL as? MetadataViews.ExternalURL {
				self.externalViewURL = e.url
			}
		}
		views.remove(key: "ExternalURL")

		// Edition
		self.editions=[] 
		if let editions = views["Editions"] {
			if let e = editions as? MetadataViews.Editions {
				if e.infoList.length > 0 {
					self.editions=e.infoList
				}
			}
		}
		views.remove(key: "Editions")

		// Serial
		self.serial=nil
		if let serial = views["Serial"] {
			if let s = serial as? MetadataViews.Serial {
				self.serial=s.number
			}
		}
		views.remove(key: "Serial")

		// subCollection
		self.collection=nil
		if let grouping = views["NFTCollectionDisplay"] {
			if let sc = grouping as? MetadataViews.NFTCollectionDisplay {
				self.collection=NFTCollectionDisplay(sc)
			}
		}
		views.remove(key: "NFTCollectionDisplay")

		// Medias 
		self.media={}
		if let medias= views["Medias"] {
			if let ms = medias as? MetadataViews.Medias {
				for m in ms.items {
					let url = m.file.uri() 
					let type = m.mediaType
					self.media[url] = type
				}
			}
		}
		views.remove(key: "Medias")

		// Rarity 
		self.rarity=nil
		if let rarity= views["Rarity"] {
			if let r = rarity as? MetadataViews.Rarity {
				self.rarity = r
			}
		}
		views.remove(key: "Rarity")

		// Traits
		self.traits=[] 
		if let traits = views["Traits"] {
			if let t = traits as? MetadataViews.Traits {
				if t.traits.length > 0 {
					self.traits=t.traits
				}
			}
		}
		views.remove(key: "Traits")

		// License 
		self.license= nil 
		if let license= views["License"] {
			if let l = license as? MetadataViews.License {
				self.license = l.spdxIdentifier
			}
		}
		views.remove(key: "License")

		self.views=[]

		for view in pointer.getViews() {
			if defaultViews().contains(view) {
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

pub struct NFTCollectionDisplay {
	// Name that should be used when displaying this NFT collection.
	pub let name: String

	// Description that should be used to give an overview of this collection.
	pub let description: String

	// External link to a URL to view more information about this collection.
	pub let externalURL: String

	// Square-sized image to represent this collection.
	pub let squareImage: {String : String}

	// Banner-sized image for this collection, recommended to have a size near 1200x630.
	pub let bannerImage: {String : String}

	// Social links to reach this collection's social homepages.
	// Possible keys may be "instagram", "twitter", "discord", etc.
	pub let socials: {String: String}

	init(
		_ nftCD : MetadataViews.NFTCollectionDisplay
	) {
		self.name = nftCD.name
		self.description = nftCD.description
		self.externalURL = nftCD.externalURL.url

		let squareImage = {nftCD.squareImage.file.uri() : nftCD.squareImage.mediaType}
		self.squareImage = squareImage

		let bannerImage = {nftCD.bannerImage.file.uri() : nftCD.bannerImage.mediaType}
		self.bannerImage = bannerImage

		let socials : {String : String} = {}
		for key in nftCD.socials.keys{
			socials[key] = nftCD.socials[key]!.url
		}
		self.socials = socials
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

	if account.balance > 0.0 {
		// check link for market
		let linkedForMarket = account.getCapability<&{MetadataViews.ResolverCollection}>(getPublicPath(project)).check()

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

		var report : {String : ListingTypeReport} = {}

		// check if that's soulBound, if yes, the report will be nil
		if !pointer.checkSoulBound() {
			let tenantCap = FindMarket.getTenantCapability(findAddress)!
			let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up. Tenant : ".concat(tenantCap.address.toString()))

			let marketTypes = FindMarket.getSaleItemTypes()

			for marketType in marketTypes {
				if let allowedListing = tenantRef.getAllowedListings(nftType: pointer.getItemType(), marketType: marketType) {
					report[FindMarket.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing, pointer: pointer, tenantRef: tenantRef)
				}
			}
		}
		return NFTDetailReport(findMarket:findMarket, storefront:nil, nftDetail: nftDetail, allowedListingActions: report, linkedForMarket : linkedForMarket)
	}
	return nil

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

	var nftViews: {String : AnyStruct} = {}
	var resolvedViews: [Type] = []
	let viewResolver = pointer.getViewResolver()

	let defaultViews = defaultViews()
	for view in views {
		if let runTimeType = CompositeType(view) {
			if !defaultViews.contains(runTimeType) {
				defaultViews.append(runTimeType)
			}
		}
	}


	for runTimeType in defaultViews {
		// Resolve arrayed views to ensure we didn't miss any stuff 
		if runTimeType == Type<MetadataViews.Editions>() {
			if let editions = MetadataViews.getEditions(viewResolver) {
				if let edition = getEdition(viewResolver) {
					var check = false
					for item in editions.infoList {
						if item.name == edition.name && item.number == edition.number && item.max == edition.max {
							check = true
							break
						}
					}
					// If the edition does not exist in editions, add it in
					if !check {
						let array = editions.infoList 
						array.append(edition)
						nftViews["Editions"] = MetadataViews.Editions(array)
						resolvedViews.append(runTimeType)
						continue
					}
				} 
				// If edition does not exist OR edition is already in editions , append it to views and continue
				nftViews["Editions"] = editions
				resolvedViews.append(runTimeType)
				continue
			}
		}

		if runTimeType == Type<MetadataViews.Edition>() {
			// If the editions does not exist, check if there is edition, if there is, add it in as editions
			if nftViews["Editions"] == nil {
				if let edition = getEdition(viewResolver) {
					nftViews["Editions"] = MetadataViews.Editions([edition])
					resolvedViews.append(runTimeType)
				}
			} 
			continue
		}

		if runTimeType == Type<MetadataViews.Medias>() {
			if let medias = MetadataViews.getMedias(viewResolver) {
				if let media = getMedia(viewResolver) {
					var check = false 
					let uri = media.file.uri()
					for item in medias.items {
						if item.file.uri() == uri {
							check = true 
							break
						}
						if !check {
							let array = medias.items
							array.append(media)
							nftViews["Medias"] = MetadataViews.Medias(array)
							resolvedViews.append(runTimeType)
							continue
						}
					}
				} 
				nftViews["Medias"] = medias
				resolvedViews.append(runTimeType)
				continue
			}
		}

		if runTimeType == Type<MetadataViews.Media>() {
			if nftViews["Medias"] == nil {
				if let media = getMedia(viewResolver) {
					nftViews["Medias"] = MetadataViews.Medias([media])
					resolvedViews.append(runTimeType)
				}
			}
			continue
		}

		if runTimeType == Type<MetadataViews.Traits>() {
			if let traits = MetadataViews.getTraits(viewResolver) {
				if let trait = getTrait(viewResolver) {
					var check = false 
					for item in traits.traits {
						if item.name == trait.name {
							check = true 
							break
						}
						if !check {
							let array = traits.traits
							array.append(trait)
							nftViews["Traits"] = MetadataViews.Traits(array)
							resolvedViews.append(runTimeType)
							continue
						}
					}
				} 
				nftViews["Traits"] = traits
				resolvedViews.append(runTimeType)
				continue
			}
		}

		if runTimeType == Type<MetadataViews.Trait>() {
			if nftViews["Traits"] == nil {
				if let trait = getTrait(viewResolver) {
					nftViews["Traits"] = MetadataViews.Traits([trait])
					resolvedViews.append(runTimeType)
				}
			} 
			continue
		}

		if let view = pointer.resolveView(runTimeType) {
			nftViews[runTimeType.identifier.slice(from: "A.1d7e57aa55817448.MetadataViews.".length, upTo: runTimeType.identifier.length)] = view
			resolvedViews.append(runTimeType)
		}
	}
	
	return NFTDetail(pointer, views: nftViews, resolvedViews: resolvedViews)


}

pub fun getEdition(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.Edition? {
	if let view = viewResolver.resolveView(Type<MetadataViews.Edition>()) {
		if let v = view as? MetadataViews.Edition {
			return v
		}
	}
	return nil
}

pub fun getMedia(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.Media? {
	if let view = viewResolver.resolveView(Type<MetadataViews.Media>()) {
		if let v = view as? MetadataViews.Media {
			return v
		}
	}
	return nil
}

pub fun getTrait(_ viewResolver: &{MetadataViews.Resolver}) : MetadataViews.Trait? {
	if let view = viewResolver.resolveView(Type<MetadataViews.Trait>()) {
		if let v = view as? MetadataViews.Trait {
			return v
		}
	}
	return nil
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

pub fun defaultViews() : [Type] {
	return [
	Type<MetadataViews.Display>() ,
	Type<MetadataViews.Editions>() , 
	Type<MetadataViews.Edition>() ,
	Type<MetadataViews.Serial>() , 
	Type<MetadataViews.Medias>() ,
	Type<MetadataViews.Media>() ,
	Type<MetadataViews.License>() , 
	Type<MetadataViews.ExternalURL>() , 
	Type<MetadataViews.NFTCollectionDisplay>() , 
	Type<MetadataViews.Traits>() , 
	Type<MetadataViews.Trait>() ,
	Type<MetadataViews.Rarity>() 
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

pub fun getPublicPath(_ nftIdentifier: String) : PublicPath {
	if let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys {
		let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
		return collection.collectionData.publicPath
	}

	if let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier :nftIdentifier) {
		return collection.collectionData.publicPath
	}
	panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
}
