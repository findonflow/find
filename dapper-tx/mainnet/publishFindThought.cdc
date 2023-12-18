import MetadataViews from 0x1d7e57aa55817448
import FindThoughts from 0x097bafa4e0b48eef
import FINDNFTCatalog from 0x097bafa4e0b48eef
import FindViews from 0x097bafa4e0b48eef
import FindUtils from 0x097bafa4e0b48eef

transaction(header: String , body: String , tags: [String], mediaHash: String?, mediaType: String?, quoteNFTOwner: Address?, quoteNFTType: String?, quoteNFTId: UInt64?, quoteCreator: Address?, quoteId: UInt64?) {

    let collection : &FindThoughts.Collection

    prepare(account: auth(BorrowValue) &Account) {
        let thoughtsCap= account.getCapability<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
        if !thoughtsCap.check() {
            account.storage.save(<- FindThoughts.createEmptyCollection(), to: FindThoughts.CollectionStoragePath)
            account.link<&FindThoughts.Collection{FindThoughts.CollectionPublic , ViewResolver.ResolverCollection}>(
                FindThoughts.CollectionPublicPath,
                target: FindThoughts.CollectionStoragePath
            )
        }
        self.collection=account.borrow<&FindThoughts.Collection>(from: FindThoughts.CollectionStoragePath) ?? panic("Cannot borrow thoughts reference from path")
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
                let cap = getAccount(quoteNFTOwner!).getCapability<&{ViewResolver.ResolverCollection}>(path)
                nftPointer = FindViews.ViewReadPointer(cap: cap, id: quoteNFTId!)
        }

        var quote : FindThoughts.ThoughtPointer? = nil 
        if quoteCreator != nil {
            quote = FindThoughts.ThoughtPointer(creator: quoteCreator!, id: quoteId!)
        }

        self.collection.publish(header: header, body: body, tags: tags, media: media, nftPointer: nftPointer, quote: quote)
    }
}
