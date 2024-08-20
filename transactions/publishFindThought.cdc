import "MetadataViews"
import "FindThoughts"
import "FINDNFTCatalog"
import "FindViews"
import "FindUtils"

transaction(header: String , body: String , tags: [String], mediaHash: String?, mediaType: String?, quoteNFTOwner: Address?, quoteNFTType: String?, quoteNFTId: UInt64?, quoteCreator: Address?, quoteId: UInt64?) {

    let collection : auth(FindThoughts.Owner) &FindThoughts.Collection

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, UnpublishCapability) &Account) {

        let col= account.storage.borrow<auth(FindThoughts.Owner) &FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath)
        if col == nil {
            account.storage.save( <- FindThoughts.createEmptyCollection(), to: FindThoughts.CollectionStoragePath)
            account.capabilities.unpublish(FindThoughts.CollectionPublicPath)
            //TODO: i do not think we can store an auth cap in a publis path
            let cap = account.capabilities.storage.issue<&FindThoughts.Collection>(FindThoughts.CollectionStoragePath)
            account.capabilities.publish(cap, at: FindThoughts.CollectionPublicPath)
            self.collection=account.storage.borrow<auth(FindThoughts.Owner) &FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
        }else {
            self.collection=col!
        }
    }

    execute {

        var media : MetadataViews.Media? = nil 
        if mediaHash != nil {
            var file : {MetadataViews.File}? = nil  
            if FindUtils.hasPrefix(mediaHash!, prefix: "ipfs://") {
            file = MetadataViews.IPFSFile(cid: mediaHash!.slice(from: "ipfs://".length , upTo: mediaHash!.length), path: nil) 
        } else {
            file = MetadataViews.HTTPFile(url: mediaHash!) 
        }
        media = MetadataViews.Media(file: file!, mediaType: mediaType!)
    }

    var nftPointer : FindViews.ViewReadPointer? = nil 
    if quoteNFTOwner != nil {
        let path = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: quoteNFTType!)?.publicPath ?? panic("This nft type is not supported by NFT Catalog. Type : ".concat(quoteNFTType!))

        nftPointer = FindViews.createViewReadPointer(address:quoteNFTOwner!, path: path, id:quoteNFTId!)
    }

    var quote : FindThoughts.ThoughtPointer? = nil 
    if quoteCreator != nil {
        quote = FindThoughts.ThoughtPointer(creator: quoteCreator!, id: quoteId!)
    }

    self.collection.publish(header: header, body: body, tags: tags, media: media, nftPointer: nftPointer, quote: quote)
}
}
