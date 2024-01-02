import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"
import ExampleNFT from "../contracts/standard/ExampleNFT.cdc"
import Debug from "../contracts/Debug.cdc"

transaction() {
    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController,UnpublishCapability) &Account) {

        let col= account.storage.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- ExampleNFT.createEmptyCollection(), to: ExampleNFT.CollectionStoragePath)
            account.capabilities.unpublish(ExampleNFT.CollectionPublicPath)
            let cap = account.capabilities.storage.issue<&ExampleNFT.Collection>(ExampleNFT.CollectionStoragePath)
            account.capabilities.publish(cap, at: ExampleNFT.CollectionPublicPath)
        }
    }
}

