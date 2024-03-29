import FindThoughts from "../contracts/FindThoughts.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(ids: [UInt64], hide: [Bool]) {

	let collection : &FindThoughts.Collection

	prepare(account: AuthAccount) {
		self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
	}

	execute {
		for i, id in ids {
			self.collection.hide(id: id, hide: hide[i])
		}

	}
}
