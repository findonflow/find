import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

import RaribleNFT from 0x01ab36aaf654a13e

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

	return fetchRaribleNFTs(user: user, collectionIDs: collectionIDs)
}
pub let FlowverseSocksIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]

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

pub fun fetchRaribleNFTs(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	let source = "RaribleNFT"
	let account = resolveAddress(user: user)
	if account == nil { return {} }
	if account!.balance == 0.0 {
		return {}
	}

	let items : {String : [MetadataCollectionItem]} = {}

	let fetchingIDs = collectionIDs
	for project in fetchingIDs.keys {

		var collectionItems : [MetadataCollectionItem] = []
		for id in fetchingIDs[project]! {

			if !FlowverseSocksIds.contains(id) {
				continue
			}
            
			let image = "https://img.rarible.com/prod/video/upload/t_video_big/prod-itemAnimations/FLOW-A.01ab36aaf654a13e.RaribleNFT:15029/b1cedf3"
			let item = MetadataCollectionItem(
				id: id,
				name: "Flowverse socks",
				collection: "Flowverse socks",
				subCollection: nil, 
				media: image,
				mediaType: "video",
				source: source, 
				nftDetailIdentifier: project 
			)
			collectionItems.append(item)
		}

		if collectionItems.length > 0 {
			items[project] = collectionItems
		}
	}
	return items
}
