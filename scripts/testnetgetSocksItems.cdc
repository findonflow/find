import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

	return {}
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
	pub let uuid:UInt64?
	pub let name: String
	pub let collection: String // <- This will be Alias unless they want something else
	pub let project: String

	pub let media  : String
	pub let mediaType : String
	pub let source : String

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

pub fun resolveAddress(user: String) : PublicAccount? {
	let address = FIND.resolve(user)
	if address == nil {
		return nil
	}
	return getAccount(address!)
}

