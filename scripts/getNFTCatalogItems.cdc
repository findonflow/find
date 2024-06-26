import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindViews from "../contracts/FindViews.cdc"

import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	return fetchNFTCatalog(user: user, collectionIDs: collectionIDs)
}

pub struct NFTView {
	pub let id: UInt64
	pub let display: MetadataViews.Display?
	pub let edition: UInt64?
	pub let collectionDisplay: MetadataViews.NFTCollectionDisplay?
	pub let soulBounded: Bool
	pub let nftType: Type

	init(
		id : UInt64,
		display : MetadataViews.Display?,
		edition : UInt64?,
		collectionDisplay: MetadataViews.NFTCollectionDisplay?,
		soulBounded: Bool ,
		nftType: Type
	) {
		self.id = id
		self.display = display
		self.edition = edition
		self.collectionDisplay = collectionDisplay
		self.soulBounded = soulBounded
		self.nftType = nftType
	}
}

pub fun getNFTs(ownerAddress: Address, ids: {String : [UInt64]}) : [NFTView] {

	let account = getAuthAccount(ownerAddress)

	if account.balance == 0.0 {
		return []
	}

	let results : [NFTView] = []
	for collectionKey in ids.keys {
		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let storagePath = catalogEntry.collectionData.storagePath
		let ref= account.borrow<&{MetadataViews.ResolverCollection}>(from: storagePath)
		if ref != nil{
			for id in ids[collectionKey]! {
				// results.append(MetadataViews.getNFTView(id:id, viewResolver: ref!.borrowViewResolver(id:id)!))
				let viewResolver = ref!.borrowViewResolver(id:id)!

				var e : UInt64? = nil
				if let editions =  MetadataViews.getEditions(viewResolver) {
					if editions.infoList.length > 0 {
						e = editions.infoList[0].number
					}
				}

				if let v = viewResolver.resolveView(Type<MetadataViews.Edition>()) {
					if let edition = v as? MetadataViews.Edition {
						e = edition.number
					}
				}

				results.append(
					NFTView(
						id : id,
						display: MetadataViews.getDisplay(viewResolver),
						edition : e,
						collectionDisplay : MetadataViews.getNFTCollectionDisplay(viewResolver),
						soulBounded : FindViews.checkSoulBound(viewResolver),
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
	pub let edition: UInt64?
	pub let collection: String // <- This will be Alias unless they want something else
	pub let subCollection: String? // <- This will be Alias unless they want something else
	pub let nftDetailIdentifier: String
	pub let soulBounded: Bool

	pub let media  : String
	pub let mediaType : String
	pub let source : String

	init(id:UInt64, name: String, edition: UInt64?, collection: String, subCollection: String?, media  : String, mediaType : String, source : String, nftDetailIdentifier: String, soulBounded: Bool ) {
		self.id=id
		self.name=name
		self.edition=edition
		self.collection=collection
		self.subCollection=subCollection
		self.media=media
		self.mediaType=mediaType
		self.source=source
		self.nftDetailIdentifier=nftDetailIdentifier
		self.soulBounded=soulBounded
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
// Fetch Specific Collections in FIND Catalog
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
			if project != nft.collectionDisplay!.name {
			 subCollection = nft.collectionDisplay!.name
			}

			var name = nft.display!.name
			if name == "" {
				name = projectName
			}

			let item = MetadataCollectionItem(
				id: nft.id,
				name: name,
				edition: nft.edition,
				collection: project,
				subCollection: subCollection,
				media: nft.display!.thumbnail.uri(),
				mediaType: "image/png",
				source: source,
				nftDetailIdentifier: nft.nftType.identifier,
				soulBounded: nft.soulBounded
			)
			collectionItems.append(item)
		}

		if collectionItems.length > 0 {
			items[project] = collectionItems
		}
	}
	return items
}
