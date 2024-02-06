import "FIND"
import "NonFungibleToken"
import "MetadataViews"
import "ExampleNFT"

transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		let dandyCap= account.getCapability<&{NonFungibleToken.Collection}>(ExampleNFT.CollectionPublicPath)
		if !dandyCap.check() {
			account.storage.save<@NonFungibleToken.Collection>(<- ExampleNFT.createEmptyCollection(), to: ExampleNFT.CollectionStoragePath)
			account.link<&ExampleNFT.Collection{NonFungibleToken.Collection, ViewResolver.ResolverCollection, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPublicPath,
				target: ExampleNFT.CollectionStoragePath
			)
			account.link<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, ViewResolver.ResolverCollection, ExampleNFT.ExampleNFTCollectionPublic}>(
				ExampleNFT.CollectionPrivatePath,
				target: ExampleNFT.CollectionStoragePath
			)
		}
	}
}
