import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTCatalog from 0x49a7cda3a1eecc29

pub fun main(user: String, maxItems: Int, collections: [String]) : {String : ItemReport} {
	return fetchNFTCatalog(user: user, maxItems: maxItems, targetCollections:collections)
}

pub struct ItemReport {
	pub let items : [MetadataCollectionItem]
	pub let length : Int // mapping of collection to no. of ids 
	pub let extraIDs : [UInt64]
	pub let shard : String 

	init(items: [MetadataCollectionItem],  length : Int, extraIDs :[UInt64] , shard: String) {
		self.items=items 
		self.length=length 
		self.extraIDs=extraIDs
		self.shard=shard
	}
}

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let name: String
	pub let collection: String // <- This will be Alias unless they want something else
	pub let subCollection: String? // <- This will be Alias unless they want something else

	pub let media  : String
	pub let mediaType : String 
	pub let source : String 

	init(id:UInt64, name: String, collection: String, subCollection: String?, media  : String, mediaType : String, source : String) {
		self.id=id
		self.name=name 
		self.collection=collection 
		self.subCollection=subCollection 
		self.media=media 
		self.mediaType=mediaType 
		self.source=source
	}
}

// Helper function 

pub fun resolveAddress(user: String) : Address? {
	return FIND.resolve(user)
}

pub fun getNFTs(ownerAddress: Address, ids: {String : [UInt64]}) : [MetadataViews.NFTView] {

	let account = getAuthAccount(ownerAddress)
	let results : [MetadataViews.NFTView] = []
	for collectionKey in ids.keys {
		let catalogEntry = NFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let tempPathStr = "catalog".concat(collectionKey)
		let tempPublicPath = PublicPath(identifier: tempPathStr)!
		let cap= account.getCapability<&{MetadataViews.ResolverCollection}>(tempPublicPath)
		if cap.check(){
			let collection = cap.borrow()!
			for id in ids[collectionKey]! {
				results.append(MetadataViews.getNFTView(id:id, viewResolver: collection.borrowViewResolver(id:id)!))
			}
		}
	}
	return results
}

pub fun getNFTIDs(ownerAddress: Address) : {String:[UInt64]} {

	let account = getAuthAccount(ownerAddress)

	let inventory : {String:[UInt64]}={}
	let types = NFTCatalog.getCatalogTypeData()
	for nftType in types.keys {

		let typeData=types[nftType]!
		let collectionKey=typeData.keys[0]
		let catalogEntry = NFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let tempPathStr = "catalog".concat(collectionKey)
		let tempPublicPath = PublicPath(identifier: tempPathStr)!
		account.link<&{MetadataViews.ResolverCollection}>(tempPublicPath, target: catalogEntry.collectionData.storagePath)
		let cap= account.getCapability<&{MetadataViews.ResolverCollection}>(tempPublicPath)
		if cap.check(){
			inventory[collectionKey] = cap.borrow()!.getIDs()
		}
	}
	return inventory
}

pub fun fetchNFTCatalog(user: String, maxItems: Int, targetCollections: [String]) : {String : ItemReport} {
	let source = "NFTCatalog"
	let account = resolveAddress(user: user)
	if account == nil { return {} }


	let extraIDs = getNFTIDs(ownerAddress: account!)
	let inventory : {String : ItemReport} = {}
	var fetchedCount : Int = 0

	for project in extraIDs.keys {
		if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
			extraIDs.remove(key: project)
			continue
		}
		
		let collectionLength = extraIDs[project]!.length

		// by pass if this is not the target collection
		if targetCollections.length > 0 && !targetCollections.contains(project) {
			// inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
			continue
		}

		
		if fetchedCount >= maxItems {
			inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source)
			continue
		}

		var fetchArray : [UInt64] = []
		if extraIDs[project]!.length + fetchedCount > maxItems {
			while fetchedCount < maxItems {
				fetchArray.append(extraIDs[project]!.remove(at: 0))
				fetchedCount = fetchedCount + 1
			}
		}else {
			fetchArray = extraIDs.remove(key: project)! 
			fetchedCount = fetchedCount + fetchArray.length
		}

		let returnedNFTs = getNFTs(ownerAddress: account!, ids: {project : fetchArray})

		var collectionItems : [MetadataCollectionItem] = []
		for nft in returnedNFTs {
			if nft == nil {
				continue
			}
			
			var subCollection = ""
			if project != nft!.collectionDisplay!.name {
			 subCollection = nft!.collectionDisplay!.name
			}
			
			let item = MetadataCollectionItem(
				id: nft!.id,
				name: nft!.display!.name,
				collection: project,
				subCollection: subCollection, 
				media: nft!.display!.thumbnail.uri(),
				mediaType: "image/png",
				source: source
			)
			collectionItems.append(item)
		}
		inventory[project] = ItemReport(items: collectionItems,  length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source)

	}

	return inventory

}

