import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String) : Report {

    if let address = FIND.resolve(user){
        let runTimeType : Type = Type<@NonFungibleToken.NFT>()

        let types = FindLostAndFoundWrapper.getSpecificRedeemableTypes(user: address, specificType: runTimeType)

        let account = getAuthAccount(address)

        let initiableStorage : [String] = []
        let relinkableStorage : [String] = []
        let initiatedStorage : [String] = []
        let problematicStorage : [String] = []
        let notSupportedType : [String] = []
        for type in types {

            let nftInfo = FINDNFTCatalog.getCollectionDataForType(nftTypeIdentifier: type.identifier)

            if nftInfo == nil {
                initiableStorage.append(type.identifier)
                continue
            }

            let storageType = account.type(at: nftInfo!.storagePath)
            if storageType == nil {
                initiableStorage.append(type.identifier)
                continue
            } 
            
            let storageTypeIdentifier = storageType!.identifier.slice(from: 0 , upTo: storageType!.identifier.length - ".Collection".length)
            let typeIdentifier = type.identifier.slice(from: 0 , upTo: type.identifier.length - ".NFT".length)
            if storageTypeIdentifier != typeIdentifier {
                problematicStorage.append(type.identifier)
            } else {

                // check if relink needed
                if account.getCapability<&{NonFungibleToken.Receiver, NonFungibleToken.Collection, ViewResolver.ResolverCollection}>(nftInfo!.publicPath).check() {
                    initiatedStorage.append(type.identifier)
                } else {
                    relinkableStorage.append(type.identifier)
                }

            }
        }
        return Report(initiableStorage: initiableStorage, relinkableStorage: relinkableStorage ,initiatedStorage: initiatedStorage, problematicStorage: problematicStorage, notSupportedType: notSupportedType, err: nil)
    }
    return logErr("cannot resolve user")

}

pub struct Report {

    pub let initiableStorage : [String] 
    pub let relinkableStorage : [String]
    pub let initiatedStorage : [String] 
    pub let problematicStorage : [String] 
    pub let notSupportedType : [String] 

    pub let err : String? 

    init(initiableStorage : [String] , relinkableStorage : [String] , initiatedStorage : [String], problematicStorage : [String] , notSupportedType : [String] , err : String? ) {
        self.initiableStorage = initiableStorage
        self.relinkableStorage = relinkableStorage
        self.initiatedStorage = initiatedStorage
        self.problematicStorage = problematicStorage
        self.notSupportedType = notSupportedType
        self.err = err
    }

}

pub fun logErr(_ err: String) : Report {
    return Report(initiableStorage: [] , relinkableStorage : [] , initiatedStorage : [] , problematicStorage: [], notSupportedType: [], err: err)
}
