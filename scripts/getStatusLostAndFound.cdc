import FIND from "../contracts/FIND.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"

access(all) main(user: String) :  {String : NFTCatalog.NFTCollectionData} {
	let lostAndFoundTypes: {String : NFTCatalog.NFTCollectionData}={}

	if let address=FIND.resolve(user) {
		let account=getAccount(address)
		if account.balance > 0.0 {
			// NFTCatalog Output
			let nftCatalogTypes = FINDNFTCatalog.getCatalogTypeData()
			let types : {String : NFTCatalog.NFTCollectionData} = {}
			for type in FindLostAndFoundWrapper.getSpecificRedeemableTypes(user: address, specificType: Type<@NonFungibleToken.NFT>()) {
				types[type.identifier] = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: type.identifier)
			}
		}
	}
	return lostAndFoundTypes
}

