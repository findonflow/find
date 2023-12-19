

import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import Admin from "../contracts/Admin.cdc"

transaction(
    collectionIdentifier : String,
    contractName: String,
    contractAddress: Address,
    nftTypeIdentifer: String,
    storagePathIdentifier: String,
    access(all)licPathIdentifier: String,
    privatePathIdentifier: String,
    access(all)licLinkedTypeIdentifier : String,
    access(all)licLinkedTypeRestrictions : [String],
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
            access(all)licPath: PublicPath(identifier : access(all)licPathIdentifier)!,
            privatePath: PrivatePath(identifier: privatePathIdentifier)!,
            access(all)licLinkedType : RestrictedType(identifier : access(all)licLinkedTypeIdentifier, restrictions: access(all)licLinkedTypeRestrictions)!,
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




 