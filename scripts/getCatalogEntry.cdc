import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(collectionIdentifier : String) : NFTCatalog.NFTCatalogMetadata? {
	return FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier) 
}
