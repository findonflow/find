import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) struct MetadataCollections {

	access(all) let items: {String : MetadataCollectionItem}
	access(all) let collections: {String : [String]}
	// supports new contracts that supports metadataViews 
	access(all) let curatedCollections: {String : [String]}

	init(items: {String : MetadataCollectionItem}, collections: {String : [String]}, curatedCollections: {String: [String]}) {
		self.items=items
		self.collections=collections
		self.curatedCollections=curatedCollections
	}
}


access(all) struct MetadataCollection{
	access(all) let type: String
	access(all) let items: [MetadataCollectionItem]

	init(type:String, items: [MetadataCollectionItem]) {
		self.type=type
		self.items=items
	}
}

// Collection Index.cdc Address : [{Path, ID}]
/* 
	access(all) struct CollectionItemPointer {
		access(all) let path 
		access(all) let id 
	}
 */
// Need : A metadata collection index : -> path, id, collection (Where do you want to group them)
// A list of these for all the items (Like collections and cur)

// Resolve Partial Collection.cdc Address, {path : [IDs]}
// Address
// [path1 , path1, path2]
// [id1 , id2, id3]
// Another list -> take these path, id, collection and return the specific collection information (similar in collections)

access(all) struct MetadataCollectionItem {
	access(all) let id:UInt64
	access(all) let typeIdentifier: String
	access(all) let uuid: UInt64 
	access(all) let name: String
	access(all) let image: String
	access(all) let url: String
	access(all) let contentTypes:[String]
	access(all) let rarity:MetadataViews.Rarity?
	//Refine later 
	access(all) let medias: [MetadataViews.Media]
	access(all) let collection: String // <- This will be Alias unless they want something else
	access(all) let traits: [MetadataViews.Trait]

	init(id:UInt64, type: Type, uuid: UInt64, name:String, image:String, url:String, contentTypes: [String], rarity: MetadataViews.Rarity?, medias: [MetadataViews.Media], collection: String, traits: [MetadataViews.Trait]) {
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
		self.traits=traits
	}
}

access(all) fun main(user: String) : MetadataCollections? {

	let resolvingAddress = FIND.resolve(user)
	if resolvingAddress == nil {
		return nil
	}
	let address = resolvingAddress!
	var resultMap : {String : MetadataCollectionItem} = {}
	let account = getAccount(address)

		if account.balance == 0.0 {
			return nil
		}

	let results : {String :  [String]}={}

	for nftInfo in NFTRegistry.getNFTInfoAll().values {
		let items: [String] = []
		let resolverCollectionCap= account.getCapability<&{ViewResolver.ResolverCollection}>(nftInfo.publicPath)
		if resolverCollectionCap.check() {
			let collection = resolverCollectionCap.borrow()!
			for id in collection.getIDs() {
				let nft = collection.borrowViewResolver(id: id) 
				
				if let display= MetadataViews.getDisplay(nft) {
					var externalUrl=nftInfo.externalFixedUrl

					if let externalUrlViw=MetadataViews.getExternalURL(nft) { 
						externalUrl=externalUrlViw.url
					}

					let rarity = MetadataViews.getRarity(nft)
					let traits = MetadataViews.getTraits(nft)

					var medias : [MetadataViews.Media] = []
					if let m= MetadataViews.getMedias(nft) {
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
						traits:traits?.traits ?? [],
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

