import "MetadataViews"
import "ViewResolver"
import "FINDNFTCatalog"
import "FIND"

//Fetch a single view from a nft on a given path
access(all) fun main(address: Address, aliasOrIdentifier:String, id: UInt64, view: String) : AnyStruct? {

    let publicPath = getPublicPath(aliasOrIdentifier)

    let pp = publicPath
    let account = getAccount(address)
    if account.balance == 0.0 {
        return nil
    }
    let collection= account.capabilities.borrow<&{ViewResolver.ResolverCollection}>(pp)!

    let nft=collection.borrowViewResolver(id: id)!
    for v in nft.getViews() {
        if v.identifier== view {
            return nft.resolveView(v)
        }
    }
    return nil
}

access(all) fun getPublicPath(_ nftIdentifier: String) : PublicPath {
    let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
    let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
    return collection.collectionData.publicPath
}
