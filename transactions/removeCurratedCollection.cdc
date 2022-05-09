
transaction(name: String) {
	prepare(account: AuthAccount) {

		let path=/storage/FindCuratedCollections
		let publicPath=/public/FindCuratedCollections

		var collections : {String: [String]} = {}
		if account.borrow<&{String: [String]}>(from:path) != nil {
			 collections=account.load<{String: [String]}>(from:path)!
		}
		collections.remove(key: name)
		account.save(collections, to: path)
		let link = account.getCapability<&{String: [String]}>(publicPath)
		if !link.check() {
			account.link<&{String: [String]}>( publicPath, target: path)
		}
	}
}
