import Dandy from "../contracts/Dandy.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"


transaction() {
	prepare(account: AuthAccount) {
		account.unlink(Dandy.CollectionPrivatePath)
		account.link<&{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(Dandy.CollectionPrivatePath, target: Dandy.CollectionStoragePath)
	}
}