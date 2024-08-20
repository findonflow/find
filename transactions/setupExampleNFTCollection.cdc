import "NonFungibleToken"
import "MetadataViews"
import "ViewResolver"
import "ExampleNFT"
import "Debug"

transaction() {
    prepare(account: auth(BorrowValue, SaveValue, PublishCapability, IssueStorageCapabilityController,UnpublishCapability) &Account) {

        let col= account.storage.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- ExampleNFT.createEmptyCollection(nftType:Type<@ExampleNFT.NFT>()), to: ExampleNFT.CollectionStoragePath)
            account.capabilities.unpublish(ExampleNFT.CollectionPublicPath)
            let cap = account.capabilities.storage.issue<&ExampleNFT.Collection>(ExampleNFT.CollectionStoragePath)
            account.capabilities.publish(cap, at: ExampleNFT.CollectionPublicPath)
        }
    }
}

