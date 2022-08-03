import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main() : {String : NFTCatalog.NFTCatalogMetadata} {
	return FINDNFTCatalog.getCatalog() 
}
