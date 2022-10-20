import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

transaction(id: UInt64, cheat: Bool) {
	prepare(account: AuthAccount) {
		let ref = account.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)!
		ref.borrowExampleNFT(id: id)!.changeRoyalties(cheat)
	}
}
 