import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindUtils from "../contracts/FindUtils.cdc"
import FlovatarMarketplace from "../contracts/community/FlovatarMarketplace.cdc"
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import NFTStorefrontV2 from "../contracts/standard/NFTStorefrontV2.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindUserStatus from "../contracts/FindUserStatus.cdc"

pub fun main(user: String, path: String, id: UInt64, views: [String]): Report {
	let addr = FIND.resolve(user)
	// if address cannot be resolved, we return the name status only
	if let r = validate(addr) {
		return r
	}

	let acct = getAuthAccount(addr!)
	let path = StoragePath(identifier: path.slice(from: "/storage/".length, upTo: path.length))!
	let colRef = acct.borrow<&NonFungibleToken.Collection>(from: path)
	if colRef == nil {
		return Report(
			collection: nil,
			remark: "Cannot borrow reference to NFT Collection"
		)
	}

	let col = colRef!
	if !col.ownedNFTs.containsKey(id) {
		return Report(
			collection: nil,
			remark: "User does not own NFT with ID : ".concat(id.toString())
		)
	}


	let nftRef = col.borrowNFT(id: id)
	let nft = NFT(addr!, nftRef, views)
	let collectionDisplay = getCollectionDisplay(nftRef)


	return Report(
		collection: Collection(
			path: path,
			type: col.getType(),
			number: col.ownedNFTs.length,
			collectionDisplay:collectionDisplay,
			nft: nft
		),
		remark: nil
	)
}

pub let defaultViews : [Type] = [
	Type<MetadataViews.Display>(),
	Type<MetadataViews.ExternalURL>(),
	Type<MetadataViews.Rarity>(),
	Type<MetadataViews.Editions>(),
	Type<MetadataViews.Edition>(),
	Type<MetadataViews.Serial>(),
	Type<MetadataViews.Traits>(),
	Type<MetadataViews.Trait>(),
	Type<MetadataViews.Medias>(),
	Type<MetadataViews.Media>(),
	Type<MetadataViews.NFTCollectionDisplay>(),
	Type<MetadataViews.License>(),
	Type<FindViews.SoulBound>()
]

pub fun validate(_ addr: Address?) : Report? {
	if addr == nil {
		return Report(
			collection: nil,
			remark: "Invalid User"
		)
	}

	if getAccount(addr!).balance == 0.0 {
		return Report(
			collection: nil,
			remark: "Uninitialized User"
		)
	}
	return nil
}

pub struct Report {
	pub let collection: Collection?
	pub let remark: String?

	init(
		collection: Collection? ,
		remark: String?
	) {
		self.collection = collection
		self.remark = remark
	}
}

pub struct Collection {
	pub let path: StoragePath
	pub let type: String
	pub let number: Int
	pub var catalogData: CatalogData?
	pub let nft: NFT

	init(
		path: StoragePath,
		type: Type,
		number: Int,
		collectionDisplay: MetadataViews.NFTCollectionDisplay?,
		nft: NFT
	) {
		self.path=path
		self.type=type.identifier
		self.number=number
		self.catalogData = nil
		let nftType = FindUtils.trimSuffix(type.identifier, suffix: "Collection")
		if let cd = FINDNFTCatalog.getMetadataFromType(CompositeType(nftType.concat("NFT"))!) {
			self.catalogData = CatalogData(
				contractName : cd.contractName,
				contractAddress : cd.contractAddress,
				collectionDisplay: cd.collectionDisplay,
			)
		}

		self.nft=nft
	}
}

pub struct CatalogData {
	pub let contractName : String
	pub let contractAddress : Address
	pub let collectionDisplay: MetadataViews.NFTCollectionDisplay

	init(
		contractName : String,
		contractAddress : Address,
		collectionDisplay: MetadataViews.NFTCollectionDisplay,
	) {
		self.contractName=contractName
		self.contractAddress=contractAddress
		self.collectionDisplay=collectionDisplay
	}
}

pub struct NFT {
	pub let uuid: UInt64
	pub let id: UInt64
	pub let display: MetadataViews.Display?
	pub var rarity:MetadataViews.Rarity?
	pub var editions: [MetadataViews.Edition]
	pub var serial: UInt64?
	pub var traits: [MetadataViews.Trait]
	pub let soulBounded: Bool
	pub let type: String
	pub let externalURL: String?
	pub let media : {String : String}
	pub let license : String?
	pub let views : [String]
	pub let data: {String : AnyStruct}
	pub let findMarket: {String : FindMarket.SaleItemInformation}
	pub let storefront: FindUserStatus.StorefrontListing?
	pub let storefrontV2: FindUserStatus.StorefrontListing?
	pub let flowty: FindUserStatus.FlowtyListing?
	pub let flowtyRental: FindUserStatus.FlowtyRental?
	pub let flovatar: FindUserStatus.FlovatarListing?
	pub let flovatarComponent: FindUserStatus.FlovatarComponentListing?
	pub var allowedListing: {String : ListingTypeReport}?

	init(
		_ user: Address,
		_ nft: &NonFungibleToken.NFT,
		_ views: [String]
	) {
		self.uuid = nft.uuid
		self.id = nft.id
		self.type = nft.getType().identifier
		self.display = getDisplay(nft)
		self.editions = getEditions(nft)
		self.rarity = getRarity(nft)
		self.serial = getSerial(nft)?.number
		self.traits = getTraits(nft)
		self.soulBounded = getSoulBound(nft)==nil ?false:true
		self.externalURL = getExternalURL(nft)?.url
		self.media = getMedias(nft)
		self.license = getLicense(nft)?.spdxIdentifier
		self.views = getViews(nft)
		self.data = getExtraViews(nft, views: views)
		self.allowedListing = nil


		let findAddress=FindMarket.getFindTenantAddress()
		if !self.soulBounded {
			let tenantCap = FindMarket.getTenantCapability(findAddress)!
			let tenantRef = tenantCap.borrow() ?? panic("This tenant is not set up. Tenant : ".concat(tenantCap.address.toString()))

			let marketTypes = FindMarket.getSaleItemTypes()
			var listing : {String : ListingTypeReport} = {}
			for marketType in marketTypes {
				if let allowedListing = tenantRef.getAllowedListings(nftType: nft.getType(), marketType: marketType) {
					listing[FindMarket.getMarketOptionFromType(marketType)] = createListingTypeReport(allowedListing, nft: nft, tenantRef: tenantRef)
				}
			}
		}

		self.findMarket=FindMarket.getNFTListing(tenant:findAddress, address: user, id: nft.uuid, getNFTInfo:false)
		self.storefront = FindUserStatus.getStorefrontListing(user: user, id : nft.id, type: nft.getType())
		self.storefrontV2 = FindUserStatus.getStorefrontV2Listing(user: user, id : nft.id, type: nft.getType())
		self.flowty = FindUserStatus.getFlowtyListing(user: user, id : nft.id, type: nft.getType())
		self.flowtyRental = FindUserStatus.getFlowtyRentals(user: user, id : nft.id, type: nft.getType())
		self.flovatar = FindUserStatus.getFlovatarListing(user: user, id : nft.id, type: nft.getType())
		self.flovatarComponent = FindUserStatus.getFlovatarComponentListing(user: user, id : nft.id, type: nft.getType())

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

pub fun getDisplay(_ nft: &NonFungibleToken.NFT) : MetadataViews.Display? {
	if let data = nft.resolveView(Type<MetadataViews.Display>()) {
		if let d = data as? MetadataViews.Display {
			return d
		}
	}
	return nil
}

pub fun getRarity(_ nft: &NonFungibleToken.NFT) : MetadataViews.Rarity? {
	if let data = nft.resolveView(Type<MetadataViews.Rarity>()) {
		if let d = data as? MetadataViews.Rarity {
			return d
		}
	}
	return nil
}

pub fun getEditions(_ nft: &NonFungibleToken.NFT) : [MetadataViews.Edition] {
	var list : [MetadataViews.Edition] = []
	if let data = nft.resolveView(Type<MetadataViews.Editions>()) {
		if let d = data as? MetadataViews.Editions {
			list = d.infoList
		}
	}

	if let data = nft.resolveView(Type<MetadataViews.Edition>()) {
		if let d = data as? MetadataViews.Edition {
			if list.length == 0 {
				list.append(d)
			}
		}
	}

	return list
}

pub fun getSerial(_ nft: &NonFungibleToken.NFT) : MetadataViews.Serial? {
	if let data = nft.resolveView(Type<MetadataViews.Serial>()) {
		if let d = data as? MetadataViews.Serial {
			return d
		}
	}
	return nil
}

pub fun getTraits(_ nft: &NonFungibleToken.NFT) : [MetadataViews.Trait] {
	var list : [MetadataViews.Trait] = []
	if let data = nft.resolveView(Type<MetadataViews.Traits>()) {
		if let d = data as? MetadataViews.Traits {
			list = d.traits
		}
	}

	if let data = nft.resolveView(Type<MetadataViews.Trait>()) {
		if let d = data as? MetadataViews.Trait {
			if list.length == 0 {
				list.append(d)
			}
		}
	}
	return list
}

pub fun getSoulBound(_ nft: &NonFungibleToken.NFT) : FindViews.SoulBound? {
	if let data = nft.resolveView(Type<FindViews.SoulBound>()) {
		if let d = data as? FindViews.SoulBound {
			return d
		}
	}
	return nil
}

pub fun getCollectionDisplay(_ nft: &NonFungibleToken.NFT) : MetadataViews.NFTCollectionDisplay? {
	if let data = nft.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
		if let d = data as? MetadataViews.NFTCollectionDisplay {
			return d
		}
	}
	return nil
}

pub fun getExternalURL(_ nft: &NonFungibleToken.NFT) : MetadataViews.ExternalURL? {
	if let data = nft.resolveView(Type<MetadataViews.ExternalURL>()) {
		if let d = data as? MetadataViews.ExternalURL {
			return d
		}
	}
	return nil
}

pub fun getLicense(_ nft: &NonFungibleToken.NFT) : MetadataViews.License? {
	if let data = nft.resolveView(Type<MetadataViews.License>()) {
		if let d = data as? MetadataViews.License {
			return d
		}
	}
	return nil
}

pub fun getRoyalties(_ nft: &NonFungibleToken.NFT) : MetadataViews.Royalties? {
	if let data = nft.resolveView(Type<MetadataViews.Royalties>()) {
		if let d = data as? MetadataViews.Royalties {
			return d
		}
	}
	return nil
}

pub fun getMedias(_ nft: &NonFungibleToken.NFT) : {String: String} {
	var media : {String : String } = {}
	if let data = nft.resolveView(Type<MetadataViews.Medias>()) {
		if let d = data as? MetadataViews.Medias {
			for m in d.items {
				let url = m.file.uri()
				let type = m.mediaType
				media[url] = type
			}
		}
	}

	if let data = nft.resolveView(Type<MetadataViews.Media>()) {
		if let d = data as? MetadataViews.Media {
			let url = d.file.uri()
			let type = d.mediaType
			media[url] = type
		}
	}

	return media
}

pub fun getViews(_ nft: &NonFungibleToken.NFT) : [String] {

	var views : [String] = []
	for v in nft.getViews() {
		if !defaultViews.contains(v) {
			views.append(v.identifier)
		}
	}
	return views

}

pub fun getExtraViews(_ nft: &NonFungibleToken.NFT, views: [String]) : {String: AnyStruct} {
	var map : {String : AnyStruct} = {}
	for v in views {
		let type = CompositeType(v)!
		if defaultViews.contains(type) {
			continue
		}

		if let resolved = nft.resolveView(type) {
			map[v] = resolved
		}

	}
	return map
}

/* Helper Function */
pub fun resolveRoyalties(_ nft: &NonFungibleToken.NFT) : [Royalties] {
	let array : [Royalties] = []
	let royalties = getRoyalties(nft)?.getRoyalties() ?? []
	for royalty in royalties {
		let address = royalty.receiver.address
		array.append(Royalties(royaltyName: royalty.description, address: address, findName: FIND.reverseLookup(address), cut: royalty.cut))
	}

	return array
}

pub fun resolveFindRoyalties(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, listing: Type, nft: Type, ft: Type) : [Royalties] {

	let cuts = tenantRef.getTenantCut(name:"", listingType: listing, nftType:nft, ftType:ft)

	let royalties :[Royalties] = []
	if cuts.findCut != nil {
		royalties.append(Royalties(royaltyName: cuts.findCut!.description, address: cuts.findCut!.receiver.address, findName: FIND.reverseLookup(cuts.findCut!.receiver.address), cut: cuts.findCut!.cut))
	}

	if cuts.tenantCut != nil {
		royalties.append(Royalties(royaltyName: cuts.tenantCut!.description, address: cuts.tenantCut!.receiver.address, findName: FIND.reverseLookup(cuts.tenantCut!.receiver.address), cut: cuts.tenantCut!.cut))
	}

	return royalties
}

pub var nftRoyalties : [Royalties]? = nil

pub fun createListingTypeReport(_ allowedListing: FindMarket.AllowedListing, nft: &NonFungibleToken.NFT, tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}) : ListingTypeReport {
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
			nftRoyalties = resolveRoyalties(nft)
			nftR = nftRoyalties
		}

		let findR = resolveFindRoyalties(tenantRef: tenantRef, listing: allowedListing.listingType , nft: nft.getType(), ft: ft)
		findR.appendAll(nftR!)

		listingDetails.append(ListingRoyalties(ftAlias: alias, ftIdentifier: ft.identifier, royalties: findR))
	}

	return ListingTypeReport(listingType: listingType, ftAlias: ftAlias, ftIdentifiers: ftIdentifier,  status: allowedListing.status , ListingDetails: listingDetails)
}
