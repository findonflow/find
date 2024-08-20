import "NFTCatalog"
import "FINDNFTCatalog"

access(all) fun main() : {String : NFTCatalog.NFTCatalogMetadata} {
	return FINDNFTCatalog.getCatalog() 
}
