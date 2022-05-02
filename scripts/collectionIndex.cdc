import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FindViews from "../contracts/FindViews.cdc"

pub struct MetadataCollections {

	pub let publicPath: PublicPath 
	pub let id: UInt64 

	init(publicPath: PublicPath, id: UInt64) {
		self.publicPath = publicPath
		self.id = id 
	}
}

pub fun main(address: Address) : [MetadataCollections] {

	var resultMap : [MetadataCollections] = []
	let account = getAccount(address)
	for nftInfo in NFTRegistry.getNFTInfoAll().values {
		let publicPath = nftInfo.publicPath
		let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
		if resolverCollectionCap.check() {
			let collection = resolverCollectionCap.borrow()!
			for id in collection.getIDs() {
				resultMap.append(MetadataCollections(publicPath: publicPath, id: id))
			}
		}
	}

	return resultMap
}
