import "NonFungibleToken"
import "Dandy"
import "MetadataViews"

transaction {
	prepare(account: auth(BorrowValue) &Account) {
		account.unlink(Dandy.CollectionPrivatePath)
		account.unlink(Dandy.CollectionPublicPath)
		destroy <- account.load<@NonFungibleToken.Collection>(from:Dandy.CollectionStoragePath)

		let dandyCap= account.getCapability<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
		if !dandyCap.check() {
			account.storage.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
			account.link<&Dandy.Collection{NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPublicPath,
				target: Dandy.CollectionStoragePath
			)
			account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.Collection, NonFungibleToken.Receiver, ViewResolver.ResolverCollection, Dandy.CollectionPublic}>(
				Dandy.CollectionPrivatePath,
				target: Dandy.CollectionStoragePath
			)
		}
	}
}
