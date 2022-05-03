import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"

pub fun main(address: Address) : [String] {

	var resultMap : [String] = []
	let account = getAccount(address)
	for nftInfo in NFTRegistry.getNFTInfoAll().values {
		let publicPath = nftInfo.publicPath
		let publicPathIdentifier = nftInfo.publicPathIdentifier
		let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
		if resolverCollectionCap.check() {
			let collection = resolverCollectionCap.borrow()!
			for id in collection.getIDs() {
				resultMap.append(publicPathIdentifier.concat("/").concat(id.toString()))
			}
		}
	}

	return resultMap
}
