

import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(
    collectionIdentifier : String,
    contractName: String,
    contractAddress: Address,
    addressWithNFT: Address,
    nftID: UInt64,
    publicPathIdentifier: String
) {

    let adminResource: &Admin.AdminProxy

    prepare(acct: AuthAccount) {
        self.adminResource = acct.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute {

        let nftAccount = getAccount(addressWithNFT)
        let pubPath = PublicPath(identifier: publicPathIdentifier)!
        let collectionCap = nftAccount.getCapability<&AnyResource{ViewResolver.ResolverCollection}>(pubPath)
        assert(collectionCap.check(), message: "MetadataViews Collection is not set up properly, ensure the Capability was created/linked correctly.")
        let collectionRef = collectionCap.borrow()!
        assert(collectionRef.getIDs().length > 0, message: "No NFTs exist in this collection.")
        let nftResolver = collectionRef.borrowViewResolver(id: nftID)

		// return early if already in catalog
		if FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: nftResolver.getType().identifier) != nil {
			return
		}


        let metadataCollectionData = MetadataViews.getNFTCollectionData(nftResolver)!

        let collectionData = NFTCatalog.NFTCollectionData(
            storagePath: metadataCollectionData.storagePath,
            publicPath: metadataCollectionData.publicPath,
            privatePath: metadataCollectionData.providerPath,
            publicLinkedType : metadataCollectionData.publicLinkedType,
            privateLinkedType : metadataCollectionData.providerLinkedType
        )

        let collectionDisplay = MetadataViews.getNFTCollectionDisplay(nftResolver)!

        let catalogData = NFTCatalog.NFTCatalogMetadata(
            contractName: contractName,
            contractAddress: contractAddress,
            nftType: nftResolver.getType(),
            collectionData: collectionData,
            collectionDisplay : collectionDisplay
        )

        self.adminResource.addCatalogEntry(collectionIdentifier : collectionIdentifier, metadata : catalogData)
    }
}
