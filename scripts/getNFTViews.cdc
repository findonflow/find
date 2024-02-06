import "MetadataViews"
import "NFTCatalog"
import "ViewResolver"
import "FINDNFTCatalog"
import "FIND"

//get all the views for an nft and address/path/id
access(all) fun  main(user: String, aliasOrIdentifier:String, id: UInt64) : [String] {
    let nftInfo = getCollectionData(aliasOrIdentifier) 

    let resolveAddress = FIND.resolve(user) 
    if resolveAddress == nil {return []}
    let address = resolveAddress!
    let pp = nftInfo.publicPath
    let collection= getAccount(address).capabilities.borrow<&{ViewResolver.ResolverCollection}>(pp)!
    let nft=collection.borrowViewResolver(id: id)!
    let views:[String]=[]
    for v in nft.getViews() {
        views.append(v.identifier)
    }
    return views
}

access(all) fun getCollectionData(_ nftIdentifier: String) : NFTCatalog.NFTCollectionData {
    let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
    let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
    return collection.collectionData
}
