import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		destroy account.load<@ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)
	}
}
