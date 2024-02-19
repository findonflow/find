
transaction(name: String, items: [String]) {
	prepare(account: auth(BorrowValue | LoadValue) &Account) {

		let path=/storage/FindCuratedCollections
		let publicPath=/public/FindCuratedCollections

		var collections : {String: [String]} = {}
		if account.storage.borrow<&{String: [String]}>(from:path) != nil {
			 collections=account.storage.load<{String: [String]}>(from:path)!
		}
		collections[name] = items
		account.storage.save(collections, to: path)
		let link = account.capabilities.get<&{String: [String]}>(publicPath)
		if link == nil {
			let newCap = account.capabilities.storage.issue<&{String: [String]}>(path)
			account.capabilities.publish(newCap, at: publicPath)
		}
	}
}
