import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FIND from "../contracts/FIND.cdc"

//Fetch a single view from a nft on a given path
pub fun main(user: String, aliasOrIdentifier:String, id: UInt64, identifier: String) : AnyStruct? {

	let publicPath = getPublicPath(aliasOrIdentifier)
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return []}
	let address = resolveAddress!

	let pp = publicPath
	let account = getAccount(address)
	if account.balance == 0.0 {
		return nil
	}
	let collection= account.getCapability(pp).borrow<&{ViewResolver.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)
	for v in nft.getViews() {
		if v.identifier== identifier {
			return nft.resolveView(v)
		}
	}
	return nil
}

pub fun getPublicPath(_ nftIdentifier: String) : PublicPath {
	let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftIdentifier)) 
	let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])! 
	return collection.collectionData.publicPath
}
