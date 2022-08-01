import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FIND from "../contracts/FIND.cdc"

//get all the views for an nft and address/path/id
pub fun main(user: String, aliasOrIdentifier:String, id: UInt64) : [String] {
	let nftInfo = getCollectionData(aliasOrIdentifier) 

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return []}
	let address = resolveAddress!
	let pp = nftInfo.publicPath
	let collection= getAccount(address).getCapability(pp).borrow<&{MetadataViews.ResolverCollection}>()!
	let nft=collection.borrowViewResolver(id: id)
	let views:[String]=[]
	for v in nft.getViews() {
		views.append(v.identifier)
	}
	return views
}

pub fun getCollectionData(_ nftIdentifier: String) : NFTCatalog.NFTCollectionData {
	let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData
}