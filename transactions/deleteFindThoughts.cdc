import FindThoughts from "../contracts/FindThoughts.cdc"

transaction(ids: [UInt64]) {

	let collection : auth(FindThoughts.Owner) &FindThoughts.Collection

	prepare(account: auth(BorrowValue) &Account) {

		self.collection=account.storage.borrow<auth(FindThoughts.Owner) &FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
	}

	execute {
		for id in ids {
			self.collection.delete(id)
		}
	}
}
