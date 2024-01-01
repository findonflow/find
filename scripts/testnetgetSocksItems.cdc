import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) fun main(user: String, collectionIDs: {String : [UInt64]}) : {String : [MetadataCollectionItem]} {

	return {}
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

