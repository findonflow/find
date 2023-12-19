import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NFTCatalogAdmin from "../contracts/standard/NFTCatalogAdmin.cdc"

transaction(
    collectionIdentifier : String,
    contractName: String,
    contractAddress: Address,
    addressWithNFT: Address,
    nftID: UInt64,
    access(all)licPathIdentifier: String
) {

    let adminResource: &NFTCatalogAdmin.Admin

    prepare(acct: auth (BorrowValue) &Account) {
        self.adminResource = acct.storage.borrow<&NFTCatalogAdmin.Admin>(from: NFTCatalogAdmin.AdminStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }

    execute {

        let nftAccount = getAccount(addressWithNFT)
        let access(all)Path = PublicPath(identifier: access(all)licPathIdentifier)!
        let collectionCap = nftAccount.capabilities.get<&{ViewResolver.ResolverCollection}>(pubPath)!
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
            access(all)licPath: metadataCollectionData.publicPath,
            privatePath: metadataCollectionData.providerPath,
            access(all)licLinkedType : metadataCollectionData.publicLinkedType,
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
