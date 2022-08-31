import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

pub fun main(user: String, specificType: String?) : Report {

    if let address = FIND.resolve(user){
        var runTimeType : Type = Type<@NonFungibleToken.NFT>()
        if specificType != nil {
            let type = CompositeType(specificType!)
			if runTimeType == nil {
				return logErr("Cannot composite run time type. Type : ".concat(specificType!))
			}
            runTimeType = type!
        }

        let types = FindLostAndFoundWrapper.getSpecificRedeemableTypes(user: address, specificType: runTimeType)

        let account = getAuthAccount(address)

        let initiableStorage : [String] = []
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
                initiatedStorage.append(type.identifier)
            }
        }
        return Report(initiableStorage: initiableStorage, initiatedStorage: initiatedStorage, problematicStorage: problematicStorage, notSupportedType: notSupportedType, err: nil)
    }
    return logErr("cannot resolve user")

}

pub struct Report {

    pub let initiableStorage : [String] 
    pub let initiatedStorage : [String] 
    pub let problematicStorage : [String] 
    pub let notSupportedType : [String] 

    pub let err : String? 

    init(initiableStorage : [String] , initiatedStorage : [String], problematicStorage : [String] , notSupportedType : [String] , err : String? ) {
        self.initiableStorage = initiableStorage
        self.initiatedStorage = initiatedStorage
        self.problematicStorage = problematicStorage
        self.notSupportedType = notSupportedType
        self.err = err
    }

}

pub fun logErr(_ err: String) : Report {
    return Report(initiableStorage: [] , initiatedStorage : [] , problematicStorage: [], notSupportedType: [], err: err)
}