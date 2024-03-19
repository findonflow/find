import "FindMarket"
import "FindMarketSale"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "NFTCatalog"
import "FINDNFTCatalog"
import "FTRegistry"

transaction(nftAliasOrIdentifiers: [String], ids: [UInt64], ftAliasOrIdentifiers: [String], directSellPrices:[UFix64], validUntil: UFix64?) {

    let saleItems : &FindMarketSale.SaleItemCollection?
    let pointers : [FindViews.AuthNFTPointer]
    let vaultTypes : [Type]

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue, NonFungibleToken.Withdraw) &Account) {

        if nftAliasOrIdentifiers.length != ids.length {
            panic("The length of arrays passed in has to be the same")
        } else if nftAliasOrIdentifiers.length != ftAliasOrIdentifiers.length {
            panic("The length of arrays passed in has to be the same")
        } else if nftAliasOrIdentifiers.length != directSellPrices.length {
            panic("The length of arrays passed in has to be the same")
        }

        let marketplace = FindMarket.getFindTenantAddress()
        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let tenant = tenantCapability.borrow()!
        self.saleItems= account.storage.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
        self.vaultTypes= []
        self.pointers= []

        let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
        let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
        let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

        let saleItemCap= account.capabilities.get<&FindMarketSale.SaleItemCollection>(publicPath)
        if saleItemCap==nil {
            account.storage.save(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
            let cap = account.capabilities.storage.issue<&FindMarketSale.SaleItemCollection>(storagePath)
            account.capabilities.publish(cap, at: publicPath)
        }
        var counter = 0

        let nfts : {String : NFTCatalog.NFTCollectionData} = {}
        let fts : {String : FTRegistry.FTInfo} = {}

        while counter < ids.length {
            // Get supported NFT and FT Information from Registries from input alias
            var nft : NFTCatalog.NFTCollectionData? = nil
            var ft : FTRegistry.FTInfo? = nil

            if nfts[nftAliasOrIdentifiers[counter]] != nil {
                nft = nfts[nftAliasOrIdentifiers[counter]]
            } else {
                let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftAliasOrIdentifiers[counter])?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifiers[counter]))
                let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
                nft = collection.collectionData
                nfts[nftAliasOrIdentifiers[counter]] = nft
            }

            if fts[ftAliasOrIdentifiers[counter]] != nil {
                ft = fts[ftAliasOrIdentifiers[counter]]
            } else {
                ft = FTRegistry.getFTInfo(ftAliasOrIdentifiers[counter]) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifiers[counter]))
                fts[ftAliasOrIdentifiers[counter]] = ft
            }


            let storagePathIdentifer = nft.storagePath.toString().split(separator:"/")[1]
            let providerIdentifier = storagePathIdentifer.concat("Provider")
            let providerStoragePath = StoragePath(identifier: providerIdentifier)!

            //if this stores anything but this it will panic, why does it not return nil?
            var existingProvider= account.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>>(from: providerStoragePath) 
            if existingProvider==nil {
                existingProvider=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(collectionData.storagePath)
                //we save it to storage to memoize it
                account.storage.save(existingProvider!, to: providerStoragePath)
                log("create new cap")
            }
            var providerCap = existingProvider!

            // Get the salesItemRef from tenant
            self.pointers.append(FindViews.AuthNFTPointer(cap: providerCap, id: ids[counter]))
            self.vaultTypes.append(ft!.type)
            counter = counter + 1
        }
    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        var counter = 0
        while counter < ids.length {
            self.saleItems!.listForSale(pointer: self.pointers[counter], vaultType: self.vaultTypes[counter], directSellPrice: directSellPrices[counter], validUntil: validUntil, extraField: {})
            counter = counter + 1
        }
    }
}
