
transaction(collections: {String :  [String]}) {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		let path=/storage/FindCuratedCollections
		let publicPath=/public/FindCuratedCollections

		if account.borrow<&{String: [String]}>(from:path) != nil {
			 account.load<{String: [String]}>(from:path)
		}
		account.save(collections, to: path)

		let link = account.getCapability<&{String: [String]}>(publicPath)
		if !link.check() {
			account.link<&{String: [String]}>( publicPath, target: path)
		}
	}
}
