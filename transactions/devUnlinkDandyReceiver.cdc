import Dandy from "../contracts/Dandy.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"


transaction() {
    prepare(account: auth(UnpublishCapability) &Account) {
        account.capabilities.unpublish(Dandy.CollectionPublicPath)
    }
}
