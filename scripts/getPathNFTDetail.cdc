import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindUtils from "../contracts/FindUtils.cdc"
import FlovatarMarketplace from "../contracts/community/FlovatarMarketplace.cdc"
import NFTStorefront from "../contracts/standard/NFTStorefront.cdc"
import NFTStorefrontV2 from "../contracts/standard/NFTStorefrontV2.cdc"

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
	let nft = NFT(nftRef, views)
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

	init(
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


