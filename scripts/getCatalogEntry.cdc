import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) fun main(collectionIdentifier : String) : NFTCatalog.NFTCatalogMetadata? {
	return FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier) 
}
