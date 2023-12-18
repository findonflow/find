import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

access(all) main() : {String : {String : Bool}} {
	return FINDNFTCatalog.getCatalogTypeData() 
}
