import FIND from "../contracts/FIND.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"

transaction() {
	prepare(account: AuthAccount) {
		let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(ExampleNFT.CollectionPublicPath)
		if !dandyCap.check() {
			account.save<@NonFungibleToken.Collection>(<- ExampleNFT.createEmptyCollection(), to: ExampleNFT.CollectionStoragePath)
			account.link<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPublicPath,
				target: ExampleNFT.CollectionStoragePath
			)
			account.link<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPrivatePath,
				target: ExampleNFT.CollectionStoragePath
			)
		}
	}
}
