import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/NFTCatalog.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String) : {String : [UInt64]} {

	if let address = FIND.resolve(user) {
		var resultMap : {String : [UInt64]} = {}
		let account = getAccount(address)
		for nftInfo in NFTCatalog.getCatalog().values {
			let publicPath = nftInfo.collectionData.publicPath

			if let subCollections = NFTCatalog.getCollectionsForType(nftTypeIdentifier: nftInfo.nftType.identifier) {
				if subCollections.length < 1 {
					continue
				} else if subCollections.length == 1 {
					let collection = nftInfo.nftType.identifier
					let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)
					if resolverCollectionCap.check() {
						let collection = resolverCollectionCap.borrow()!
						resultMap[nftInfo.collectionDisplay.name] = collection.getIDs()
					}
				} else {
					let collection = nftInfo.nftType.identifier
					let resolverCollectionCap= account.getCapability<&{MetadataViews.ResolverCollection}>(publicPath)

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
