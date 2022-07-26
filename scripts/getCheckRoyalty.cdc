import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTCatalog from "../contracts/NFTCatalog.cdc"

pub fun main(name: String, id: UInt64, nftAliasOrIdentifier: String, viewIdentifier: String) : AnyStruct? {

	let address =FIND.lookupAddress(name)!

	// Get collection public path from NFT Registry
	let collectionPublicPath = getPublicPath(nftAliasOrIdentifier)
	let collection= getAccount(address).getCapability(collectionPublicPath).borrow<&{MetadataViews.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)
	for v in nft.getViews() {
		if v.identifier== viewIdentifier {
			return nft.resolveView(v)
		}
	}
	return nil
}

pub fun getPublicPath(_ nftIdentifier: String) : PublicPath {
	let collectionIdentifier = NFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = NFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData.publicPath
}