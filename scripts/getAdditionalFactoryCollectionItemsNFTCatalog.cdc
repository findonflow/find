import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	return fetchNFTCatalog(user: user, collectionIDs: collectionIDs)
}

pub struct NFTView {
	pub let id: UInt64
	pub let display: MetadataViews.Display?
	pub let editions: MetadataViews.Editions?
	pub let collectionDisplay: MetadataViews.NFTCollectionDisplay?
	pub let nftType: Type

	init(
		id : UInt64,
		display : MetadataViews.Display?,
		editions : MetadataViews.Editions?,
		collectionDisplay: MetadataViews.NFTCollectionDisplay?,
		nftType: Type
	) {
		self.id = id
		self.display = display
		self.editions = editions
		self.collectionDisplay = collectionDisplay
		self.nftType = nftType
	}
}

pub fun getNFTs(ownerAddress: Address, ids: {String : [UInt64]}) : [NFTView] {

	let account = getAuthAccount(ownerAddress)
	let results : [NFTView] = []
	for collectionKey in ids.keys {
		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let storagePath = catalogEntry.collectionData.storagePath
		let ref= account.borrow<&{MetadataViews.ResolverCollection}>(from: storagePath)
		if ref != nil{
			for id in ids[collectionKey]! {
				// results.append(MetadataViews.getNFTView(id:id, viewResolver: ref!.borrowViewResolver(id:id)!))
				let viewResolver = ref!.borrowViewResolver(id:id)!
				results.append(
					NFTView(
						id : id,
						display: MetadataViews.getDisplay(viewResolver),
						editions : MetadataViews.getEditions(viewResolver),
						collectionDisplay : MetadataViews.getNFTCollectionDisplay(viewResolver),
						nftType : viewResolver.getType()
					)
				)
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
	pub let nftDetailIdentifier: String

	pub let media  : String
	pub let mediaType : String 
	pub let source : String 

	init(id:UInt64, name: String, collection: String, subCollection: String?, media  : String, mediaType : String, source : String, nftDetailIdentifier: String) {
		self.id=id
		self.name=name 
		self.collection=collection 
		self.subCollection=subCollection 
		self.media=media 
		self.mediaType=mediaType 
		self.source=source
		self.nftDetailIdentifier=nftDetailIdentifier
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

		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:project)!
		let projectName = catalogEntry.contractName

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

			var name = nft!.display!.name 
			if name == "" {
				name = projectName
			}

			if nft.editions != nil && nft.editions!.infoList.length > 0 {
				let edition = nft.editions!.infoList[0].number.toString()
				// check if the name ends with "editionNumber"
				// If the name ends with "editionNumber", we do not concat the edition
				if name.length > edition.length && name.slice(from: name.length - edition.length, upTo: name.length) != edition {
					name = name.concat("#").concat(nft.editions!.infoList[0].number.toString())
				}
			}
			
			let item = MetadataCollectionItem(
				id: nft!.id,
				name: name,
				collection: projectName,
				subCollection: subCollection, 
				media: nft!.display!.thumbnail.uri(),
				mediaType: "image/png",
				source: source, 
				nftDetailIdentifier: nft!.nftType.identifier
			)
			collectionItems.append(item)
		}

		if collectionItems.length > 0 {
			items[project] = collectionItems
		}
	}
	return items
}
