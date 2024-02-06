import "Dandy"
import "NonFungibleToken"
import "MetadataViews"


transaction() {
    prepare(account: auth(UnpublishCapability) &Account) {
        account.capabilities.unpublish(Dandy.CollectionPublicPath)
        //TODO: issue a new capability that does not have NonFungibleToken.Collection but only  ViewResolver.ResolverCollection for instance
    }
}
