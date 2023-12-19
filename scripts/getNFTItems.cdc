import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindViews from "../contracts/FindViews.cdc"


access(all) main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

	let report : { String: [MetadataCollectionItem]}= { }
	let address = FIND.resolve(user)

	if address==nil{
		return report
	}

	let account = getAuthAccount(address!)

	if account.balance == 0.0 {
		return report
	}


	for collection in collectionIDs.keys {
		let ids = collectionIDs[collection]!

		let storagePath = StoragePath(identifier:collection)!
		let colRef = account.borrow<&NonFungibleToken.Collection>(from: storagePath)
		if colRef ==nil{
			return  report
		}

		let col = colRef!

		let results : [MetadataCollectionItem] = []
		var triedFetchingData=false
		for i, id in ids {

				let nft = col.borrowNFT(id: id)


				let display=getDisplay(nft)
				if display==nil{
					continue;
				}
				let collectionDisplay=getCollectionDisplay(nft)
				results.append(MetadataCollectionItem(
					id: nft.id,
					uuid: nft.uuid,
					name: display!.name,
					collection: collectionDisplay?.name ?? collection,
					storagePath: collection,
					identifier:nft.getType().identifier,
					media: display!.thumbnail.uri()
				))
		}

		report[collection]=results
	}
	return report
}

access(all) struct MetadataCollectionItem {
	pub let id:UInt64
	pub let uuid:UInt64
	pub let name: String
	pub let collection: String
	pub let storagePath: String
	pub let nftIdentifier:String
	pub let media  : String
	pub let mediaType  : String
	pub let source  : String
	pub let project : String
	pub let community : String

	init(id:UInt64, uuid:UInt64, name: String, collection: String, storagePath:String, identifier: String, media  : String) {
		self.id=id
		self.uuid=uuid
		self.name=name
		self.storagePath=storagePath
		self.collection=collection
		self.nftIdentifier=identifier
		self.media=media
		self.mediaType="image"
		self.source="getNFTDetails"
		self.project=storagePath
		self.community="getNFTDetailsCommunity"
	}
}

access(all) getDisplay(_ nft: &NonFungibleToken.NFT) : MetadataViews.Display? {
	if let data = nft.resolveView(Type<MetadataViews.Display>()) {
		if let d = data as? MetadataViews.Display {
			return d
		}
	}
	return nil
}

access(all) getCollectionDisplay(_ nft: &NonFungibleToken.NFT) : MetadataViews.NFTCollectionDisplay? {
	if let data = nft.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
		if let d = data as? MetadataViews.NFTCollectionDisplay {
			return d
		}
	}
	return nil
}
