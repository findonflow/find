import Dandy from "../contracts/Dandy.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"

transaction() {
	prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {
		account.capabilities.unpublish(Dandy.CollectionPublicPath)
	}
}
