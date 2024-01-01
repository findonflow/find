import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) fun main(collectionIdentifier : String, type: String?) : NFTCatalogMetadata? {
	if let catalog = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier) {
		return NFTCatalogMetadata(
			contractName : catalog.contractName, 
			contractAddress : catalog.contractAddress, 
			nftType: catalog.nftType, 
			collectionDisplay : catalog.collectionDisplay
		)
	}

	// if we have type identifier here: loop thru the items in that specific type
	// otherwise we just loop over the entire catalog to get the collection display
	var types : [String] = FINDNFTCatalog.getCatalogTypeData().keys 
	if type != nil {
		types = [type!]
	}

	for identifier in types {
		if let collections : [String] = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: identifier)?.keys {
			for ci in collections {
				let catalog = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : ci)! 
				if catalog.collectionDisplay.name == collectionIdentifier {
					return NFTCatalogMetadata(
						contractName : catalog.contractName, 
						contractAddress : catalog.contractAddress, 
						nftType: catalog.nftType, 
						collectionDisplay : catalog.collectionDisplay
					)
				}
			}
		}
	}

	return nil
}

access(all) struct NFTCatalogMetadata {
	access(all) let contractName : String
	access(all) let contractAddress : Address
	access(all) let nftType: String
	access(all) let collectionDisplay: MetadataViews.NFTCollectionDisplay

	init (contractName : String, contractAddress : Address, nftType: Type, collectionDisplay : MetadataViews.NFTCollectionDisplay) {
		self.contractName = contractName
		self.contractAddress = contractAddress
		self.nftType = nftType.identifier
		self.collectionDisplay = collectionDisplay
	}
}
