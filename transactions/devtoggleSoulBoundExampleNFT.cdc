import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

transaction(id: UInt64, soulBound: Bool) {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		let ref = account.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)!
		ref.borrowExampleNFT(id: id)!.toggleSoulBound(soulBound)
	}
}
