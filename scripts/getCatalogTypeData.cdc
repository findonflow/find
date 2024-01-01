import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) fun main() : {String : {String : Bool}} {
	return FINDNFTCatalog.getCatalogTypeData() 
}
