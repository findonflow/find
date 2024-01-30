import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) fun main(name: String, id: UInt64, nftAliasOrIdentifier: String, viewIdentifier: String) : AnyStruct? {

    let address =FIND.resolve(name)!

    // Get collection public path from NFT Registry
    let collectionPublicPath = getPublicPath(nftAliasOrIdentifier)
    let collection= getAccount(address).capabilities.borrow<&{ViewResolver.ResolverCollection}>(collectionPublicPath)!

    let nft=collection.borrowViewResolver(id: id)!
    return nft.resolveView(CompositeType(viewIdentifier)!)
}

access(all) fun getPublicPath(_ nftIdentifier: String) : PublicPath {
    let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
    let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
    return collection.collectionData.publicPath
}