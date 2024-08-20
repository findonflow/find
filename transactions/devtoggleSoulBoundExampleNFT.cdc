import "ExampleNFT"

transaction(id: UInt64, soulBound: Bool) {
	prepare(account: auth(BorrowValue) &Account) {
		let ref = account.storage.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)!
		ref.borrowExampleNFT(id: id)!.toggleSoulBound(soulBound)
	}
}
