import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(name: String, id: UInt64, nftAliasOrIdentifier: String, viewIdentifier: String) : AnyStruct? {

	let address =FIND.resolve(name)!

	// Get collection public path from NFT Registry
	let collectionPublicPath = getPublicPath(nftAliasOrIdentifier)
	let collection= getAuthAccount(address).borrow<&{MetadataViews.ResolverCollection}>(from: collectionPublicPath)!

	// let nft=collection.borrowViewResolver(id: id)
	let nft=collection.borrowViewResolver(id: collection.getIDs()[0])
	for v in nft.getViews() {
		if v.identifier== viewIdentifier {
			return nft.resolveView(v)
		}
	}
	return nil
}

pub fun getPublicPath(_ nftIdentifier: String) : StoragePath {
	let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData.storagePath
}