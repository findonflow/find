import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import RaribleNFT from 0x01ab36aaf654a13e

pub fun main(user: String, maxItems: Int, collections: [String]) : {String : ItemReport} {
	return fetchRaribleNFT(user: user, maxItems: maxItems, targetCollections: collections)
}

pub let FlowverseSocksIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]

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

pub fun getNFTIDs(ownerAddress: Address) : {String:[UInt64]} {

	let account = getAuthAccount(ownerAddress)

	let inventory : {String:[UInt64]}={}

	let tempPathStr = "RaribleNFT"
	let tempPublicPath = PublicPath(identifier: tempPathStr)!
	account.link<&RaribleNFT.Collection>(tempPublicPath, target: RaribleNFT.collectionStoragePath)
	let cap= account.getCapability<&RaribleNFT.Collection>(tempPublicPath)
	if cap.check(){
			// let rarible : [UInt64] = []
			let socks : [UInt64] = []
		for id in cap.borrow()!.getIDs() {
			if FlowverseSocksIds.contains(id) {
				socks.append(id)
			// } else {
			// 	rarible.append(id)
			}
		}

		// inventory["RaribleNFT"] = rarible
		inventory["FlowverseSocks"] = socks

	}
	
	return inventory
}

pub fun fetchRaribleNFT(user: String, maxItems: Int, targetCollections: [String]) : {String : ItemReport} {
	let source = "RaribleNFT"
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

		var collectionItems : [MetadataCollectionItem] = []
		for id in fetchArray {
			
			let image = "https://img.rarible.com/prod/video/upload/t_video_big/prod-itemAnimations/FLOW-A.01ab36aaf654a13e.RaribleNFT:15029/b1cedf3"
			let item = MetadataCollectionItem(
				id: id,
				name: "Flowverse socks",
				collection: "Flowverse socks",
				subCollection: nil, 
				media: image,
				mediaType: "video",
				source: source
			)
			collectionItems.append(item)
		}
		inventory[project] = ItemReport(items: collectionItems,  length : collectionLength, extraIDs :extraIDs[project] ?? [] , shard: source)

	}

	return inventory

}