import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main() : {String : {String : Bool}} {
	return FINDNFTCatalog.getCatalogTypeData() 
}
