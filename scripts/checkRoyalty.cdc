import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import Profile from "../contracts/Profile.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"

pub fun main(name: String, id: UInt64, nftAlias: String, identifier: String) : AnyStruct? {

	let address =FIND.lookupAddress(name)!

	// Get collection public path from NFT Registry
	let nftInfo = NFTRegistry.getNFTInfoByAlias(nftAlias) ?? panic("This NFT is not supported by the Find Market yet")
	let collectionPublicPath = nftInfo.publicPath
	let collection= getAccount(address).getCapability(collectionPublicPath).borrow<&{MetadataViews.ResolverCollection}>()!

	let nft=collection.borrowViewResolver(id: id)
	for v in nft.getViews() {
		if v.identifier== identifier {
			return nft.resolveView(v)
		}
	}
	return nil
}

