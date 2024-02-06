

import "MetadataViews"
import "NFTCatalog"
import "Admin"

transaction(
    collectionIdentifier : String,
    contractName: String,
    contractAddress: Address,
    nftTypeIdentifer: String,
    storagePathIdentifier: String,
    publicPathIdentifier: String,
    privatePathIdentifier: String,
    publicLinkedTypeIdentifier : String,
    publicLinkedTypeRestrictions : [String],
    privateLinkedTypeIdentifier : String,
    privateLinkedTypeRestrictions : [String],
    collectionName : String,
    collectionDescription: String,
    externalURL : String,
    squareImageMediaCID : String,
    squareImageMediaType : String,
    bannerImageMediaCID : String,
    bannerImageMediaType : String,
    socials: {String : String},
) {
    
    let adminResource: &Admin.AdminProxy
    
    prepare(acct: auth(BorrowValue) &Account) {
        self.adminResource = acct.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath) ?? panic("Cannot borrow Admin Reference.")
    }
    
    execute {
        let collectionData = NFTCatalog.NFTCollectionData(
            storagePath: StoragePath(identifier: storagePathIdentifier)!,
            publicPath: PublicPath(identifier : publicPathIdentifier)!,
            privatePath: PrivatePath(identifier: privatePathIdentifier)!,
            publicLinkedType : RestrictedType(identifier : publicLinkedTypeIdentifier, restrictions: publicLinkedTypeRestrictions)!,
            privateLinkedType : RestrictedType(identifier : privateLinkedTypeIdentifier, restrictions: privateLinkedTypeRestrictions)!
        )

        let squareMedia = MetadataViews.Media(
                        file: MetadataViews.IPFSFile(
                            cid: squareImageMediaCID, 
                            path: nil
                        ),
                        mediaType: squareImageMediaType
                    )
        
        let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.IPFSFile(
                            cid: bannerImageMediaCID, 
                            path: nil
                        ),
                        mediaType: bannerImageMediaType
                    )

        let socialsStruct : {String : MetadataViews.ExternalURL} = {}
        for key in socials.keys {
            socialsStruct[key] =  MetadataViews.ExternalURL(socials[key]!)
        }
        
        let collectionDisplay = MetadataViews.NFTCollectionDisplay(
            name: collectionName,
            description: collectionDescription,
            externalURL: MetadataViews.ExternalURL(externalURL),
            squareImage: squareMedia,
            bannerImage: bannerMedia,
            socials: socialsStruct
        )

        let catalogData = NFTCatalog.NFTCatalogMetadata(
            contractName: contractName,
            contractAddress: contractAddress,
            nftType: CompositeType(nftTypeIdentifer)!,
            collectionData: collectionData,
            collectionDisplay : collectionDisplay
        )

        self.adminResource.addCatalogEntry(collectionIdentifier : collectionIdentifier, metadata : catalogData)
    }
}




 