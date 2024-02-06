import "MetadataViews"
import "NonFungibleToken"
import "ViewResolver"
import "FINDNFTCatalog"
import "NFTCatalog"
import "NFTCatalogAdmin"

transaction(
    collectionIdentifier : String,
    contractName: String,
    contractAddress: Address,
    addressWithNFT: Address,
    nftID: UInt64,
    publicPathIdentifier: String
) {

    let adminResource: &NFTCatalogAdmin.Admin

    prepare(acct: auth (BorrowValue) &Account) {
        self.adminResource = acct.storage.borrow<&NFTCatalogAdmin.Admin>(from: NFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute {

        let nftAccount = getAccount(addressWithNFT)
        let pubPath = PublicPath(identifier: publicPathIdentifier)!
        let collectionCap = nftAccount.capabilities.get<&{NonFungibleToken.Collection}>(pubPath) ?? panic("MetadataViews Collection is not set up properly, ensure the Capability was created/linked correctly.")
        let collectionRef = collectionCap.borrow()!
        assert(collectionRef.getIDs().length > 0, message: "No NFTs exist in this collection.")
        let nftResolver = collectionRef.borrowNFT(nftID) ?? panic("could not find item with id")

        // return early if already in catalog
        if FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: nftResolver.getType().identifier) != nil {
            return
        }


        let metadataCollectionData = MetadataViews.getNFTCollectionData(nftResolver)!

        let collectionData = NFTCatalog.NFTCollectionData(
            storagePath: metadataCollectionData.storagePath,
            publicPath: metadataCollectionData.publicPath,
            publicLinkedType : metadataCollectionData.publicLinkedType,
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
