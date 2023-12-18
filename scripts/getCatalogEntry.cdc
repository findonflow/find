import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) main(collectionIdentifier : String) : NFTCatalog.NFTCatalogMetadata? {
	return FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier) 
}
