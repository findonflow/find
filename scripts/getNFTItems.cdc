import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FindViews from "../contracts/FindViews.cdc"

pub fun main(address: Address, collection: String, ids: [UInt64]) :  { String : [MetadataCollectionItem]} {

	let account = getAuthAccount(address)

	let report : { String: [MetadataCollectionItem]}= { collection : []}
	if account.balance == 0.0 {
		return report
	}


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
	return report
}

pub struct MetadataCollectionItem {
	pub let id:UInt64
	pub let uuid:UInt64
	pub let name: String
	pub let collection: String 
	pub let storagePath: String
	pub let identifier:String
	pub let media  : String

	init(id:UInt64, uuid:UInt64, name: String, collection: String, storagePath:String, identifier: String, media  : String) {
		self.id=id
		self.uuid=uuid
		self.name=name
		self.storagePath=storagePath
		self.collection=collection
		self.identifier=identifier
		self.media=media
	}
}

pub fun getDisplay(_ nft: &NonFungibleToken.NFT) : MetadataViews.Display? {
	if let data = nft.resolveView(Type<MetadataViews.Display>()) {
		if let d = data as? MetadataViews.Display {
			return d
		}
	}
	return nil
}

pub fun getCollectionDisplay(_ nft: &NonFungibleToken.NFT) : MetadataViews.NFTCollectionDisplay? {
	if let data = nft.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
		if let d = data as? MetadataViews.NFTCollectionDisplay {
			return d
		}
	}
	return nil
}
