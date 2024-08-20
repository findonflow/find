import "FindMarket"
import "FindMarketSale"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FINDNFTCatalog"
import "FTRegistry"

transaction(nftAliasOrIdentifier: String, id: UInt64, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

    let saleItems : auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection?
    let pointer : FindViews.AuthNFTPointer
    let vaultType : Type

    prepare(account: auth (StorageCapabilities, IssueStorageCapabilityController,PublishCapability, Storage) &Account) {

        let marketplace = FindMarket.getFindTenantAddress()
        let tenantCapability= FindMarket.getTenantCapability(marketplace)!
        let saleItemType= Type<@FindMarketSale.SaleItemCollection>()

        let tenant = tenantCapability.borrow()!
        let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
        let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)
        let saleItemCap= account.capabilities.get<&FindMarketSale.SaleItemCollection>(publicPath)
        if !saleItemCap.check(){
            account.storage.save(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
            let cap = account.capabilities.storage.issue<&FindMarketSale.SaleItemCollection>(storagePath)
            account.capabilities.publish(cap, at: publicPath)
        }

        // Get supported NFT and FT Information from Registries from input alias
        let collectionIdentifier = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier:nftAliasOrIdentifier)?.keys ?? panic("This NFT is not supported by the NFT Catalog yet. Type : ".concat(nftAliasOrIdentifier))
        let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier[0])!
        let nft = collection.collectionData

        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

        let storagePathIdentifer = nft.storagePath.toString().split(separator:"/")[1]
        let providerIdentifier = storagePathIdentifer.concat("Provider")
        let providerStoragePath = StoragePath(identifier: providerIdentifier)!

        //if this stores anything but this it will panic, why does it not return nil?
        var existingProvider= account.storage.copy<Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>>(from: providerStoragePath) 
        if existingProvider==nil {
            existingProvider=account.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(nft.storagePath)
            //we save it to storage to memoize it
            account.storage.save(existingProvider!, to: providerStoragePath)
            log("create new cap")
        }
        var providerCap = existingProvider!

        // Get the salesItemRef from tenant
        self.saleItems= account.storage.borrow<auth(FindMarketSale.Seller) &FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))
        self.pointer= FindViews.AuthNFTPointer(cap: providerCap, id: id)
        self.vaultType= ft.type
    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})
    }
}
