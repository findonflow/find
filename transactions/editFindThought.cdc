import FindThoughts from "../contracts/FindThoughts.cdc"

transaction(id: UInt64, header: String , body: String, tags: [String]) {

	let collection : auth(FindThoughts.Owner) &FindThoughts.Collection

	prepare(account: auth(BorrowValue) &Account) {

		self.collection=account.storage.borrow<auth(FindThoughts.Owner) &FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
	}

	execute {
		let thought = self.collection.borrow(id)
		thought.edit(header: header , body: body, tags: tags)
	}
}
