
transaction(name: String) {
	prepare(account: auth(BorrowValue) &Account) {

		let path=/storage/FindCuratedCollections
		let access(all)licPath=/public/FindCuratedCollections

		var collections : {String: [String]} = {}
		if account.borrow<&{String: [String]}>(from:path) != nil {
			 collections=account.load<{String: [String]}>(from:path)!
		}
		collections.remove(key: name)
		account.storage.save(collections, to: path)
		let link = account.getCapability<&{String: [String]}>(publicPath)
		if !link.check() {
			account.link<&{String: [String]}>( access(all)licPath, target: path)
		}
	}
}
