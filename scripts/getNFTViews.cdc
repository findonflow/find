import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FIND from "../contracts/FIND.cdc"

//get all the views for an nft and address/path/id
pub fun main(user: String, aliasOrIdentifier:String, id: UInt64) : [String] {
	let nftInfo = NFTRegistry.getNFTInfo(aliasOrIdentifier) 
	if nftInfo == nil {panic("This NFT is not registered in registry. input: ".concat(aliasOrIdentifier))}

	let resolveAddress = FIND.resolve(user) 
	if resolveAddress == nil {return []}
	let address = resolveAddress!
	let pp = nftInfo!.publicPath
	let collection= getAccount(address).getCapability(pp).borrow<&{MetadataViews.ResolverCollection}>()!
	let nft=collection.borrowViewResolver(id: id)
	let views:[String]=[]
	for v in nft.getViews() {
		views.append(v.identifier)
	}
	return views
}

