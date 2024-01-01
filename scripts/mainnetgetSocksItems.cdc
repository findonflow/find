import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

import RaribleNFT from 0x01ab36aaf654a13e

access(all) fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

	return fetchRaribleNFTs(user: user, collectionIDs: collectionIDs)
}
access(all) let FlowverseSocksIds : [UInt64] = [14813, 15013, 14946, 14808, 14899, 14792, 15016, 14961, 14816, 14796, 14992, 14977, 14815, 14863, 14817, 14814, 14875, 14960, 14985, 14850, 14849, 14966, 14826, 14972, 14795, 15021, 14950, 14847, 14970, 14833, 14786, 15010, 14953, 14799, 14883, 14947, 14844, 14801, 14886, 15015, 15023, 15027, 15029, 14802, 14810, 14948, 14955, 14957, 14988, 15007, 15009, 14837, 15024, 14803, 14973, 14969, 15002, 15017, 14797, 14894, 14881, 15025, 14791, 14979, 14789, 14993, 14873, 14939, 15005, 15006, 14869, 14889, 15004, 15008, 15026, 14990, 14998, 14898, 14819, 14840, 14974, 15019, 14856, 14838, 14787, 14876, 14996, 14798, 14855, 14824, 14843, 14959, 15020, 14862, 14822, 14897, 14830, 14790, 14867, 14878, 14991, 14835, 14818, 14892, 14800, 15000, 14857, 14986, 14805, 14812, 14962]

access(all) getNFTs(ownerAddress: Address, ids: [UInt64]) : [MetadataViews.NFTView] {

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

access(all) struct CollectionReport {
	access(all) let items : {String : [MetadataCollectionItem]}
	access(all) let collections : {String : Int} // mapping of collection to no. of ids
	access(all) let extraIDs : {String : [UInt64]}

	init(items: {String : [MetadataCollectionItem]},  collections : {String : Int}, extraIDs : {String : [UInt64]} ) {
		self.items=items
		self.collections=collections
		self.extraIDs=extraIDs
	}
}

access(all) struct MetadataCollectionItem {
	access(all) let id:UInt64
	access(all) let uuid:UInt64?
	access(all) let name: String
	access(all) let collection: String // <- This will be Alias unless they want something else
	access(all) let project: String

	access(all) let media  : String
	access(all) let mediaType : String
	access(all) let source : String

	init(id:UInt64, uuid: UInt64?, name: String, collection: String, media  : String, mediaType : String, source : String, project: String) {
		self.id=id
		self.name=name
		self.uuid=uuid
		self.collection=collection
		self.media=media
		self.mediaType=mediaType
		self.source=source
		self.project=project
	}
}

// Helper function

access(all) resolveAddress(user: String) : PublicAccount? {
	let address = FIND.resolve(user)
	if address == nil {
		return nil
	}
	return getAccount(address!)
}

access(all) fetchRaribleNFTs(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	let source = "getNFTDetailsSocks"
	let acct = resolveAddress(user: user)
	if acct == nil { return {} }
	if acct!.balance == 0.0 {
		return {}
	}
	let account = getAuthAccount(acct!.address)

	let items : {String : [MetadataCollectionItem]} = {}

	let tempPathStr = "RaribleNFTFIND"
	let tempPublicPath = PublicPath(identifier: tempPathStr)!
	account.link<&RaribleNFT.Collection>(tempPublicPath, target: RaribleNFT.collectionStoragePath)
	let cap= account.getCapability<&RaribleNFT.Collection>(tempPublicPath)
	let ref = cap.borrow()!

	let fetchingIDs = collectionIDs
	for project in fetchingIDs.keys {

		var collectionItems : [MetadataCollectionItem] = []
		for id in fetchingIDs[project]! {

			if !FlowverseSocksIds.contains(id) {
				continue
			}
			let nft = getAccount

			let image = "https://img.rarible.com/prod/video/upload/t_video_big/prod-itemAnimations/FLOW-A.01ab36aaf654a13e.RaribleNFT:15029/b1cedf3"
			let item = MetadataCollectionItem(
				id: id,
				uuid: ref.borrowNFT(id: id).uuid,
				name: "Flowverse socks",
				collection: "Flowverse socks",
				media: image,
				mediaType: "video",
				source: source,
				project: project
			)
			collectionItems.append(item)
		}

		if collectionItems.length > 0 {
			items[project] = collectionItems
		}
	}
	return items
}
