import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import ViewResolver from "../contracts/standard/ViewResolver.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FIND from "../contracts/FIND.cdc"

//get all the views for an nft and address/path/id
access(all) fun  main(address: Address, aliasOrIdentifier:String, id: UInt64) : [String] {
    let nftInfo = getCollectionData(aliasOrIdentifier) 

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