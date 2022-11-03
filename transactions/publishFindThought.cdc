import FindThoughts from "../contracts/FindThoughts.cdc"

transaction(header: String , body: String , tags: [String], mediaHash: String, mediaType: String) {

	let collection : &FindThoughts.Collection

	prepare(account: AuthAccount) {

		self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
	}

	execute {
		self.collection.publish(header: header, body: body, tags: tags, mediaHash: mediaHash, mediaType: mediaType)
	}
}
