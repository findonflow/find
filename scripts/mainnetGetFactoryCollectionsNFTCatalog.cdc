import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTCatalog from 0x49a7cda3a1eecc29

pub fun main(user: String, maxItems: Int) : CollectionReport? {
	return fetchNFTCatalog(user: user, maxItems: maxItems, targetCollections:[])
}

pub struct CollectionReport {
	pub let items : {String : [MetadataCollectionItem]} 
	pub let collections : {String : Int} // mapping of collection to no. of ids 
	pub let extraIDs : {String : [UInt64]} 

	init(items: {String : [MetadataCollectionItem]},  collections : {String : Int}, extraIDs : {String : [UInt64]} ) {
		self.items=items 
		self.collections=collections 
		self.extraIDs=extraIDs
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

pub fun resolveAddress(user: String) : PublicAccount? {
	let address = FIND.resolve(user)
	if address == nil {
		return nil
	}
	return getAccount(address!)
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

//////////////////////////////////////////////////////////////
// Fetch All Collections in Shard 1
//////////////////////////////////////////////////////////////
pub fun fetchNFTCatalog(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
	let source = "NFTCatalog"
	let account = resolveAddress(user: user)
	if account == nil { return nil }

	let items : {String : [MetadataCollectionItem]} = {}

	let extraIDs = getNFTIDs(ownerAddress: account!.address)

	for project in extraIDs.keys {
		if extraIDs[project]! == nil || extraIDs[project]!.length < 1{
			extraIDs.remove(key: project)
		}
	}
	let collections : {String : Int} = {}
	for key in extraIDs.keys {
		collections[key] = extraIDs[key]!.length
	}
	let fetchingIDs : {String : [UInt64]} = {}
	var fetchedCount : Int = 0
	for project in extraIDs.keys {

		// by pass if this is not the target collection
		if targetCollections.length > 0 && !targetCollections.contains(project) {
			continue
		}

		if extraIDs[project]!.length + fetchedCount > maxItems {
			let array : [UInt64] = []
			while fetchedCount < maxItems {
				array.append(extraIDs[project]!.remove(at: 0))
				fetchedCount = fetchedCount + 1
			}
			if array.length > 0 {
				fetchingIDs[project] = array
			}
			break
		}

		let array = extraIDs.remove(key: project)! 
		fetchedCount = fetchedCount + array.length
		fetchingIDs[project] = array
	}


	for project in fetchingIDs.keys {
		let returnedNFTs = getNFTs(ownerAddress: account!.address, ids: {project : fetchingIDs[project]!})

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

		if collectionItems.length > 0 {
			items[project] = collectionItems
		}
	}
	return CollectionReport(items: items,  collections : collections, extraIDs : extraIDs)
}


