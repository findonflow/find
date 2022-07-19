import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

import RaribleNFT from 0x01ab36aaf654a13e

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

	return fetchRaribleNFTs(user: user, collectionIDs: collectionIDs)
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

pub fun fetchRaribleNFTs(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {
	let source = "RaribleNFT"
	let account = resolveAddress(user: user)
	if account == nil { return {} }

	let items : {String : [MetadataCollectionItem]} = {}

	let fetchingIDs = collectionIDs
	for project in fetchingIDs.keys {
		let returnedNFTs = getNFTs(ownerAddress: account!.address, ids: collectionIDs[project]!)

		var collectionItems : [MetadataCollectionItem] = []
		for nft in returnedNFTs {
			if nft == nil {
				continue
			}
			
			let item = MetadataCollectionItem(
				id: nft!.id,
				name: nft!.display!.name,
				collection:"RaribleNFT" ,
				subCollection: project, 
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
