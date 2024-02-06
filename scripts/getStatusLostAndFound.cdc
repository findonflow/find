import "FIND"
import "FINDNFTCatalog"
import "FindLostAndFoundWrapper"
import "NFTCatalog"
import "NonFungibleToken"

access(all) fun main(user: String) :  {String : NFTCatalog.NFTCollectionData} {
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

