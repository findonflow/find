import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) main(user: String) : {String : [UInt64]} {

	if let address = FIND.resolve(user) {
		var resultMap : {String : [UInt64]} = {}
		let account = getAccount(address)
		for nftInfo in FINDNFTCatalog.getCatalog().values {
			let publicPath = nftInfo.collectionData.publicPath

			if let subCollections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftInfo.nftType.identifier) {
				if subCollections.length < 1 {
					continue
				} else if subCollections.length == 1 {
					let collection = nftInfo.nftType.identifier
					let resolverCollectionCap= account.getCapability<&{ViewResolver.ResolverCollection}>(publicPath)
					if resolverCollectionCap.check() {
						let collection = resolverCollectionCap.borrow()!
						resultMap[nftInfo.collectionDisplay.name] = collection.getIDs()
					}
				} else {
					let collection = nftInfo.nftType.identifier
					let resolverCollectionCap= account.getCapability<&{ViewResolver.ResolverCollection}>(publicPath)

					let array : [UInt64] = []
					if resolverCollectionCap.check() {
						let collection = resolverCollectionCap.borrow()!
						for id in collection.getIDs() {
							let vr = collection.borrowViewResolver(id: id)
							if let sc = vr.resolveView(Type<MetadataViews.NFTCollectionDisplay>()) {
								let scv = sc as! MetadataViews.NFTCollectionDisplay
								if scv.name == nftInfo.collectionDisplay.name {
									array.append(id)
								}
							}
						}
					}
					resultMap[nftInfo.collectionDisplay.name] = array
				}
			} 

		}

		return resultMap
	}
	return {}
}
