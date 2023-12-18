import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindThoughts from "../contracts/FindThoughts.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FindUtils from "../contracts/FindUtils.cdc"

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
