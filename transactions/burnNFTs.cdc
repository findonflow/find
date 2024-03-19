import "NonFungibleToken"
import "MetadataViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FindViews"
import "FIND"
import "FindFurnace"


transaction(types: [String] , ids: [UInt64], messages: [String]) {

    let authPointers : [FindViews.AuthNFTPointer]

    prepare(account : auth(Storage, IssueStorageCapabilityController) &Account) {

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


            let storagePathIdentifer = path.storagePath.toString().split(separator:"/")[1]
            let providerIdentifier = storagePathIdentifer.concat("Provider")
            let providerStoragePath = StoragePath(identifier: providerIdentifier)!

            //if this stores anything but this it will panic, why does it not return nil?
            var existingProvider= account.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>>(from: providerStoragePath) 
            if existingProvider==nil {
                existingProvider=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(path.storagePath)
                //we save it to storage to memoize it
                account.storage.save(existingProvider!, to: providerStoragePath)
                log("create new cap")
            }
            var providerCap = existingProvider!
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
