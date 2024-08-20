import "FindThoughts"
import "FIND"

transaction(ids: [UInt64], hide: [Bool]) {

	let collection : auth(FindThoughts.Owner) &FindThoughts.Collection

	prepare(account: auth(BorrowValue) &Account) {
		self.collection=account.storage.borrow<auth(FindThoughts.Owner) &FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
	}

	execute {
		for i, id in ids {
			self.collection.hide(id: id, hide: hide[i])
		}

	}
}
