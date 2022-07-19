import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import RaribleNFT from 0x01ab36aaf654a13e

pub fun main(user: String, maxItems: Int) : CollectionReport? {
	return fetchRaribleNFT(user: user, maxItems: maxItems, targetCollections:[])
}

pub let FlowverseSocksIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]

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

pub fun getNFTs(ownerAddress: Address, ids: [UInt64]) : [MetadataViews.NFTView] {

	let account = getAuthAccount(ownerAddress)
	let results : [MetadataViews.NFTView] = []
	let tempPathStr = "RaribleNFT"
	let tempPublicPath = PublicPath(identifier: tempPathStr)!
	account.link<&RaribleNFT.Collection>(tempPublicPath, target: RaribleNFT.collectionStoragePath)
	let cap= account.getCapability<&RaribleNFT.Collection>(tempPublicPath)
	if cap.check(){
		let collection = cap.borrow()!
		for id in ids {

			let authNFT = (&collection.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
			let nft = authNFT as! &RaribleNFT.NFT

			let md = nft.getMetadata()

			let display = MetadataViews.Display(
				name: md["name"] ?? "",
				description: md["description"] ?? "",
				thumbnail: MetadataViews.HTTPFile(url: md["metaURI"] ?? ""),
			)

			let view =  MetadataViews.NFTView(
				id : id,
				uuid: nft.uuid,
				display: display,
				externalURL : nil,
				collectionData : nil,
				collectionDisplay : nil,
				royalties : nil,
				traits : nil
			)
			results.append(view)
		}
	}
	
	return results
}

pub fun getNFTIDs(ownerAddress: Address) : {String:[UInt64]} {

	let account = getAuthAccount(ownerAddress)

	let inventory : {String:[UInt64]}={}

	let tempPathStr = "RaribleNFT"
	let tempPublicPath = PublicPath(identifier: tempPathStr)!
	account.link<&RaribleNFT.Collection>(tempPublicPath, target: RaribleNFT.collectionStoragePath)
	let cap= account.getCapability<&RaribleNFT.Collection>(tempPublicPath)
	if cap.check(){
			let rarible : [UInt64] = []
			let socks : [UInt64] = []
		for id in cap.borrow()!.getIDs() {
			if FlowverseSocksIds.contains(id) {
				socks.append(id)
			} else {
				rarible.append(id)
			}
		}

		inventory["RaribleNFT"] = rarible
		inventory["FlowverseSocks"] = socks

	}
	
	return inventory
}

pub fun fetchRaribleNFT(user: String, maxItems: Int, targetCollections: [String]) : CollectionReport? {
	let source = "RaribleNFT"
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
		let returnedNFTs = getNFTs(ownerAddress: account!.address, ids: fetchingIDs[project]!)

		var collectionItems : [MetadataCollectionItem] = []
		for nft in returnedNFTs {
			if nft == nil {
				continue
			}
			
			let item = MetadataCollectionItem(
				id: nft!.id,
				name: nft!.display!.name,
				collection: project,
				subCollection: nil, 
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


