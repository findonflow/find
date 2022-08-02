import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"
import AlchemyMetadataWrapperMainnetShard1 from 0xeb8cb4c3157d5dac

pub fun main(user: String) : {String : CollectionLength} {

	if let address = FIND.resolve(user) {

		return getNFTIDs_Shard1(ownerAddress: address, cacheCollections: {})

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

pub fun getNFTIDs_Shard1(ownerAddress: Address, cacheCollections: {String:CollectionLength}) : {String : CollectionLength} {
	let nfts = AlchemyMetadataWrapperMainnetShard1.getNFTIDs(ownerAddress: ownerAddress) 
	for nft in nfts.keys {
		let length = nfts[nft]!.length
		if length == 0 {
			continue
		}
		cacheCollections[nft] = CollectionLength(shard: "Shard1", length: length)
	} 
	return cacheCollections
}
