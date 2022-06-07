import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub struct MetadataCollections {

	pub let items: {String : MetadataCollectionItem}
	pub let collections: {String : [String]}
	// supports new contracts that supports metadataViews 
	pub let curatedCollections: {String : [String]}

	init(items: {String : MetadataCollectionItem}, collections: {String : [String]}, curatedCollections: {String: [String]}) {
		self.items=items
		self.collections=collections
		self.curatedCollections=curatedCollections
	}
}


pub struct MetadataCollection{
	pub let type: String
	pub let items: [MetadataCollectionItem]

	init(type:String, items: [MetadataCollectionItem]) {
		self.type=type
		self.items=items
	}
}

// Collection Index.cdc Address : [{Path, ID}]
/* 
	pub struct CollectionItemPointer {
		pub let path 
		pub let id 
	}
 */
// Need : A metadata collection index : -> path, id, collection (Where do you want to group them)
// A list of these for all the items (Like collections and cur)

// Resolve Partial Collection.cdc Address, {path : [IDs]}
// Address
// [path1 , path1, path2]
// [id1 , id2, id3]
// Another list -> take these path, id, collection and return the specific collection information (similar in collections)

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let typeIdentifier: String
	pub let uuid: UInt64 
	pub let name: String
	pub let image: String
	pub let url: String
	pub let contentTypes:[String]
	pub let rarity:String
	//Refine later 
	pub let medias: [MetadataViews.Media]
	pub let collection: String // <- This will be Alias unless they want something else
	pub let tag: {String : String}
	pub let scalar: {String : UFix64}

	init(id:UInt64, type: Type, uuid: UInt64, name:String, image:String, url:String, contentTypes: [String], rarity: String, medias: [MetadataViews.Media], collection: String, tag: {String : String}, scalar: {String : UFix64}) {
		self.id=id
		self.typeIdentifier = type.identifier
		self.uuid = uuid
		self.name=name
		self.url=url
		self.image=image
		self.contentTypes=contentTypes
		self.rarity=rarity
		self.medias=medias
		self.collection=collection
		self.tag=tag
		self.scalar=scalar
	}
}

pub fun main(user: String) : MetadataCollections? {

	let resolvingAddress = FIND.resolve(user)
	if resolvingAddress == nil {
		return nil
	}
	let address = resolvingAddress!
	var resultMap : {String : MetadataCollectionItem} = {}
	let account = getAccount(address)
	let results : {String :  [String]}={}

	for nftInfo in NFTRegistry.getNFTInfoAll().values {
		let items: [String] = []
		let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(nftInfo.publicPath)
		if resolverCollectionCap.check() {
			let collection = resolverCollectionCap.borrow()!
			for id in collection.getIDs() {
				let nft = collection.borrowViewResolver(id: id) 
				
				if let display= FindViews.getDisplay(nft) {
					var externalUrl=nftInfo.externalFixedUrl

					if let externalUrlViw=FindViews.getExternalURL(nft) { 
						externalUrl=externalUrlViw.url
					}

					var rarity=""
					if let r = FindViews.getRarity(nft) {
						rarity=r.rarityName
					}

					var tag : {String : String}={}
					if let t= FindViews.getTags(nft) {
						tag=t.getTag()
					}			

					var scalar : {String : UFix64}={}
					if let s= FindViews.getScalar(nft) {
						scalar=s.getScalar()
					}			

					var medias : [MetadataViews.Media] = []
					if let m= FindViews.getMedias(nft) {
						medias=m.items
					}	

					let cotentTypes : [String] = []
					for media in medias {
						cotentTypes.append(media.mediaType)
					}

					let item = MetadataCollectionItem(
						id: id,
						type: nft.getType() ,
						uuid: nft.uuid ,
						name: display.name,
						image: display.thumbnail.uri(),
						url: externalUrl,
						contentTypes: cotentTypes,
						rarity: rarity,
						medias: medias,
						collection: nftInfo.alias,
						tag: tag,
						scalar: scalar
					)
					let itemId = nftInfo.alias.concat(item.id.toString())
					items.append(itemId)
					resultMap.insert(key:itemId, item)
				}
			}
			results[nftInfo.alias] = items
		}
	}

	let publicPath=/public/FindCuratedCollections
	let link = account.getCapability<&{String: [String]}>(publicPath)
	var curatedCollections : {String: [String]} = {}
	if link.check() {
		let curated = link.borrow()!
		for curatedKey in curated.keys {
			curatedCollections[curatedKey] = curated[curatedKey]!
		}
	}

	return MetadataCollections(items: resultMap, collections:results, curatedCollections: curatedCollections)
}

