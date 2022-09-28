

import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import Admin from "../contracts/Admin.cdc"

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
    squareImageMediaURL : String,
    squareImageMediaType : String,
    bannerImageMediaURL : String,
    bannerImageMediaType : String,
    socials: {String : String},
) {
    
    let adminResource: &Admin.AdminProxy
    
    prepare(acct: AuthAccount) {
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
                        file: MetadataViews.HTTPFile(
                            url: squareImageMediaURL
                        ),
                        mediaType: squareImageMediaURL
                    )
        
        let bannerMedia = MetadataViews.Media(
                        file: MetadataViews.HTTPFile(
                            url: bannerImageMediaURL
                        ),
                        mediaType: bannerImageMediaURL
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




