import "ExampleNFT"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		destroy account.load<@ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)
	}
}
