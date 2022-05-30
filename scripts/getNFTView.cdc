import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"

//Fetch a single view from a nft on a given path
pub fun main(user: String, aliasOrIdentifier:String, id: UInt64, identifier: String) : AnyStruct? {

	let nftInfo = NFTRegistry.getNFTInfo(aliasOrIdentifier) 
	if nftInfo == nil {panic("This NFT is not registered in registry. input: ".concat(aliasOrIdentifier))}
	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return []}
	let address = resolveAddress!

	let pp = nftInfo!.publicPath
	let collection= getAccount(address).getCapability(pp).borrow<&{MetadataViews.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)
	for v in nft.getViews() {
		if v.identifier== identifier {
			return nft.resolveView(v)
		}
	}
	return nil
}

