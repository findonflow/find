import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String) : {String : [UInt64]} {
	if let address = FIND.resolve(user) {
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
	return {}
}
