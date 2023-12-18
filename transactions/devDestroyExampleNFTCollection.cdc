import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		destroy account.load<@ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)
	}
}
