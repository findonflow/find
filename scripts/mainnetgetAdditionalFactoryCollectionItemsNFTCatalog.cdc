import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	return fetchNFTCatalog(user: user, collectionIDs: collectionIDs)
}

pub fun getNFTs(ownerAddress: Address, ids: {String : [UInt64]}) : [MetadataViews.NFTView] {

	let account = getAuthAccount(ownerAddress)
	let results : [MetadataViews.NFTView] = []
	for collectionKey in ids.keys {
		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let tempPathStr = "catalog".concat(collectionKey)
		let tempPublicPath = PublicPath(identifier: tempPathStr)!
		account.link<&{MetadataViews.ResolverCollection}>(tempPublicPath, target: catalogEntry.collectionData.storagePath)
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


//////////////////////////////////////////////////////////////
// Fetch Specific Collections in Shard 1
//////////////////////////////////////////////////////////////
pub fun fetchNFTCatalog(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	let source = "NFTCatalog"
	let account = resolveAddress(user: user)
	if account == nil { return {} }

	let items : {String : [MetadataCollectionItem]} = {}

	let fetchingIDs = collectionIDs


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
	return items
}
