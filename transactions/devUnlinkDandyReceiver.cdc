import Dandy from "../contracts/Dandy.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		account.unlink(Dandy.CollectionPublicPath)
		account.link<&{NonFungibleToken.Collection, ViewResolver.ResolverCollection}>(Dandy.CollectionPublicPath, target: Dandy.CollectionStoragePath)
	}
}
