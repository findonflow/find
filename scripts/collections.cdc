import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"

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

// Collection Index.cdc Address : 
// Need : A metadata collection index : -> path, id, collection (Where do you want to group them)
// A list of these for all the items (Like collections and cur)

// Resolve Partial Collection.cdc Address, {path : [IDs]}
// Another list -> take these path, id, collection and return the specific collection information (similar in collections)

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let typeIdentifier: String
	pub let uuid: UInt64 
	pub let name: String
	pub let image: String
	pub let url: String
	pub let contentType:String
	pub let rarity:String
	//Refine later 
	pub let metadata: {String : String}
	pub let collection: String // <- This will be Alias unless they want something else

	init(id:UInt64, type: Type, uuid: UInt64, name:String, image:String, url:String, contentType: String, rarity: String, collection: String) {
		self.id=id
		self.typeIdentifier = type.identifier
		self.uuid = uuid
		self.name=name
		self.url=url
		self.image=image
		self.contentType=contentType
		self.rarity=rarity
		self.metadata={}
		self.collection=collection
	}
}

pub fun main(address: Address) : MetadataCollections? {

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
				
				if nft.resolveView(Type<MetadataViews.Display>()) != nil {
					let displayView = nft.resolveView(Type<MetadataViews.Display>())!
					let display = displayView as! MetadataViews.Display


					var externalUrl=nftInfo.externalFixedUrl
					if let externalUrlView = nft.resolveView(Type<MetadataViews.ExternalURL>()) {
						let url= externalUrlView as! MetadataViews.ExternalURL
						externalUrl=url.url
					}

					var rarity=""
					if let rarityView = nft.resolveView(Type<FindViews.Rarity>()) {
						let r= rarityView as! FindViews.Rarity
						rarity=r.rarityName
					}
					let item = MetadataCollectionItem(
						id: id,
						type: nft.getType() ,
						uuid: nft.uuid ,
						name: display.name,
						image: display.thumbnail.uri(),
						url: externalUrl,
						contentType: "image",
						rarity: rarity,
						collection: nftInfo.alias
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

/*
//This uses a view from Neo until we agree on another for ExternalDomainViewUrl
pub fun getItemForMetadataStandard(alias:String, path: PublicPath, account:PublicAccount, externalFixedUrl: String) : {String : MetadataCollectionItem} {
	let items: {String : MetadataCollectionItem} = {}
	let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(path)
	if resolverCollectionCap.check() {
		let collection = resolverCollectionCap.borrow()!
		for id in collection.getIDs() {
			let nft = collection.borrowViewResolver(id: id) 

			if nft.resolveView(Type<MetadataViews.Display>()) != nil {
				let displayView = nft.resolveView(Type<MetadataViews.Display>())!
				let display = displayView as! MetadataViews.Display


				var externalUrl=externalFixedUrl
				if let externalUrlView = nft.resolveView(Type<MetadataViews.ExternalURL>()) {
					let url= externalUrlView as! MetadataViews.ExternalURL
					externalUrl=url.url
				}
				let item = MetadataCollectionItem(
					id: id,
					name: display.name,
					image: display.thumbnail.uri(),
					url: externalUrl,
					listPrice: nil,
					listToken: nil,
					contentType: "image",
					rarity: ""
				)
				let itemId = alias.concat(item.id.toString())
				items[itemId] = item
			}
		}
	}
	return items

}
*/
