import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		let dandyCap= account.getCapability<&{NonFungibleToken.Collection}>(ExampleNFT.CollectionPublicPath)
		if !dandyCap.check() {
			account.storage.save<@NonFungibleToken.Collection>(<- ExampleNFT.createEmptyCollection(), to: ExampleNFT.CollectionStoragePath)
			account.link<&ExampleNFT.Collection{NonFungibleToken.Collection, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPublicPath,
				target: ExampleNFT.CollectionStoragePath
			)
			account.link<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPrivatePath,
				target: ExampleNFT.CollectionStoragePath
			)
		}
	}
}
