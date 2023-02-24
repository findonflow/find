import FindViews from "../contracts/FindViews.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindUtils from "../contracts/FindUtils.cdc"

pub fun main(user: String, path: String, ids: [UInt64]): Report {
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
	let nfts : {UInt64 : NFT} = {}

	var collectionDisplay : MetadataViews.NFTCollectionDisplay? = nil
	let extraIDs : [UInt64] = []

	for i, id in ids {
		let nft = col.borrowNFT(id: id)
		nfts[id] = NFT(
			user: addr!,
			path: path,
			nft
			)
		if collectionDisplay == nil {
			collectionDisplay = getCollectionDisplay(nft)
		}
	}

	return Report(
		collection: Collection(
			user: addr!,
			path: path,
			type: col.getType(),
			number: col.ownedNFTs.length,
			collectionDisplay:collectionDisplay,
			ids: extraIDs,
			nfts: nfts
		),
		remark: nil
	)
}

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
	pub let extraIDs: [UInt64]
	pub var catalogData: CatalogData?
	pub let nfts: {UInt64 : NFT}
	pub let script: RunScript

	init(
		user: Address,
		path: StoragePath,
		type: Type,
		number: Int,
		collectionDisplay: MetadataViews.NFTCollectionDisplay?,
		ids: [UInt64],
		nfts: {UInt64 : NFT}
	) {
		self.path=path
		self.type=type.identifier
		self.number=number
		self.extraIDs=ids
		self.catalogData = nil
		let nftType = FindUtils.trimSuffix(type.identifier, suffix: "Collection")
		if let cd = FINDNFTCatalog.getMetadataFromType(CompositeType(nftType.concat("NFT"))!) {
			self.catalogData = CatalogData(
				contractName : cd.contractName,
				contractAddress : cd.contractAddress,
				collectionDisplay: cd.collectionDisplay,
			)
		}
		self.nfts=nfts
		self.script= RunScript(
			"getPathNFTItems",
			{
				"user" : user,
				"path" : path.toString(),
				"ids" : ids
			}
		)
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
	pub let script: RunScript

	init(
		user: Address,
		path: StoragePath,
		_ nft: &NonFungibleToken.NFT
	) {
		self.uuid = nft.uuid
		self.id = nft.id
		self.display = getDisplay(nft)
		self.editions = getEditions(nft)
		self.rarity = getRarity(nft)
		self.serial = getSerial(nft)?.number
		self.traits = getTraits(nft)
		self.soulBounded = getSoulBound(nft)==nil ?false:true
		self.type = nft.getType().identifier
		self.script= RunScript(
			"getPathNFTDetail",
			{
				"user" : user,
				"path" : path.toString(),
				"id" : nft.id,
				"views" : [] as [String]
			}
		)
	}
}

pub struct RunScript {
	pub let scriptName: String
	pub let parameter: {String : AnyStruct}

	init(
		_ script: String,
		_ param: {String : AnyStruct}
	) {
		self.scriptName=script
		self.parameter=param
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
