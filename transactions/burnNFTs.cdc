import "NonFungibleToken"
import "MetadataViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FindViews"
import "FIND"
import "FindFurnace"


transaction(types: [String] , ids: [UInt64], messages: [String]) {

    let authPointers : [FindViews.AuthNFTPointer]

    prepare(account : auth(NonFungibleToken.Withdraw, IssueStorageCapabilityController) &Account) {

        self.authPointers = []

        let contractData : {Type : NFTCatalog.NFTCatalogMetadata} = {}


        for i , typeIdentifier in types {
            let type = CompositeType(typeIdentifier) ?? panic("Cannot refer to type with identifier : ".concat(typeIdentifier))

            var data : NFTCatalog.NFTCatalogMetadata? = contractData[type]
            if data == nil {
                data = FINDNFTCatalog.getMetadataFromType(type) ?? panic("NFT Type is not supported by NFT Catalog. Type : ".concat(type.identifier))
                contractData[type] = data
            }

            let path = data!.collectionData

            var providerCap = account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(path.storagePath)
            let pointer = FindViews.AuthNFTPointer(cap: providerCap, id: ids[i])
            self.authPointers.append(pointer)
        }
    }

    execute {
        let ctx : {String : String} = {
            "tenant" : "find"
        }
        for i,  pointer in self.authPointers {
            let id = ids[i] 
            ctx["message"] = messages[i]

            // burn thru furnace
            FindFurnace.burn(pointer: pointer, context: ctx)
        }
    }
}
