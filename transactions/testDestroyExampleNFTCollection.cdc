import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"


transaction() {
	prepare(account: AuthAccount) {
		destroy account.load<@ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)
	}
}
