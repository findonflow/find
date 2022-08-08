import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(user: String, maxItems: Int, collections: [String]) : {String : ItemReport} {
	return fetchNFTCatalog(user: user, maxItems: maxItems, targetCollections:collections)
}

pub struct ItemReport {
	pub let items : [MetadataCollectionItem]
	pub let length : Int // mapping of collection to no. of ids 
	pub let extraIDs : [UInt64]
	pub let shard : String 
	pub let extraIDsIdentifier : String 

	init(items: [MetadataCollectionItem],  length : Int, extraIDs :[UInt64] , shard: String, extraIDsIdentifier: String) {
		self.items=items 
		self.length=length 
		self.extraIDs=extraIDs
		self.shard=shard
		self.extraIDsIdentifier=extraIDsIdentifier
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

// Helper function 

pub fun resolveAddress(user: String) : Address? {
	return FIND.resolve(user)
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

pub fun getNFTIDs(ownerAddress: Address) : {String:[UInt64]} {

	let account = getAuthAccount(ownerAddress)

	let inventory : {String:[UInt64]}={}
	let types = FINDNFTCatalog.getCatalogTypeData()
	for nftType in types.keys {

		let typeData=types[nftType]!
		let collectionKey=typeData.keys[0]
		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let storagePath = catalogEntry.collectionData.storagePath
		let ref= account.borrow<&{MetadataViews.ResolverCollection}>(from: storagePath)
		if ref != nil {
			inventory[collectionKey] = ref!.getIDs()
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

		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:project)!
		let projectName = catalogEntry.contractName

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
			inventory[project] = ItemReport(items: [],  length : collectionLength, extraIDs :extraIDs[project]! , shard: source, extraIDsIdentifier: project)
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

			var name = nft!.display!.name 
			if name == "" {
				name = projectName
			}

			if nft.editions != nil && nft.editions!.infoList.length > 0 {
				name = name.concat("#").concat(nft.editions!.infoList[0].number.toString())
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

		inventory[catalogEntry.contractName] = ItemReport(items: collectionItems,  length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source, extraIDsIdentifier: project)

	}

	return inventory

}

