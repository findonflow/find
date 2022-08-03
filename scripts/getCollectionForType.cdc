import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"

pub fun main(nftTypeIdentifier : String) : {String : Bool}? {
	return FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftTypeIdentifier)
}
