import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(user: String) : {String : CollectionLength} {

	if let address = FIND.resolve(user) {

		return getNFTIDs_Catalog(ownerAddress: address, cacheCollections: {})

	}
	return {}

}

pub struct CollectionLength {
	pub let shard : String 
	pub let length : Int 
	init(shard : String, length : Int ) {
		self.shard=shard 
		self.length=length
	}
}

// Helper function 

pub fun resolveAddress(user: String) : Address? {
	return FIND.resolve(user)
}

pub fun getNFTIDs_Catalog(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String:CollectionLength} {

	let account = getAuthAccount(ownerAddress)

	let types = FINDNFTCatalog.getCatalogTypeData()
	for nftType in types.keys {

		let typeData=types[nftType]!
		let collectionKey=typeData.keys[0]
		let catalogEntry = FINDNFTCatalog.getCatalogEntry(collectionIdentifier:collectionKey)!
		let tempPathStr = "catalog".concat(collectionKey)
		let tempPublicPath = PublicPath(identifier: tempPathStr)!
		account.link<&NonFungibleToken.Collection>(tempPublicPath, target: catalogEntry.collectionData.storagePath)
		let cap= account.getCapability<&NonFungibleToken.Collection>(tempPublicPath)
		if cap.check(){
			let collection = cap.borrow()!
			let length = collection.ownedNFTs.length
			if length == 0 {
				continue
			}
			cacheCollections[collectionKey] = CollectionLength(shard: "NFTCatalog", length: length)
		}
	}
	return cacheCollections
}
