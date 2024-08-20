import "Dandy"
import "NonFungibleToken"
import "MetadataViews"
import "ViewResolver"

transaction() {
	prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {
		account.capabilities.unpublish(Dandy.CollectionPublicPath)
	}
}
