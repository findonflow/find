import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"

pub fun main(address: Address) : {String : [UInt64]} {

	var resultMap : {String : [UInt64]} = {}
	let account = getAccount(address)
	for nftInfo in NFTRegistry.getNFTInfoAll().values {
		let publicPath = nftInfo.publicPath
		let alias = nftInfo.alias
		let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
		if resolverCollectionCap.check() {
			let collection = resolverCollectionCap.borrow()!
			resultMap[alias] = collection.getIDs()
		}
	}

	return resultMap
}
