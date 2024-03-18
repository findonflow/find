import "FindMarket"
import "FIND"
import "FTRegistry"
import "FindLeaseMarketSale"
import "FindLeaseMarket"
import "FindMarketSale"

transaction(leaseName: String, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

    let saleItems : auth(FindLeaseMarketSale.Seller) &FindLeaseMarketSale.SaleItemCollection
    let pointer : FindLeaseMarket.AuthLeasePointer
    let vaultType : Type

    prepare(account: auth(Storage, IssueStorageCapabilityController, PublishCapability, IssueStorageCapabilityController) &Account) {

        // Get the salesItemRef from tenant
        let leaseMarketplace = FindMarket.getFindTenantAddress()
        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
        let leaseTenant = leaseTenantCapability.borrow()!

        let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
        let leasePublicPath=leaseTenant.getPublicPath(leaseSaleItemType)
        let leaseStoragePath= leaseTenant.getStoragePath(leaseSaleItemType)
        let leaseSaleItemCap= account.capabilities.get<&{FindLeaseMarket.SaleItemCollectionPublic, FindLeaseMarketSale.SaleItemCollectionPublic}>(leasePublicPath)
        if leaseSaleItemCap == nil {
            //The link here has to be a capability not a tenant, because it can change.
            account.storage.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
            let leaseSaleItemCap= account.capabilities.storage.issue<&{FindLeaseMarket.SaleItemCollectionPublic, FindLeaseMarketSale.SaleItemCollectionPublic}>(leaseStoragePath)
            account.capabilities.publish(leaseSaleItemCap, at: leasePublicPath)
        }


        self.saleItems= account.storage.borrow<auth(FindLeaseMarketSale.Seller) &FindLeaseMarketSale.SaleItemCollection>(from: leaseStoragePath)!

        // Get supported NFT and FT Information from Registries from input alias
        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
        self.vaultType= ft.type

        let storagePathIdentifer = FIND.LeaseStoragePath.toString().split(separator:"/")[1]
        let providerIdentifier = storagePathIdentifer.concat("Provider")
        let providerStoragePath = StoragePath(identifier: providerIdentifier)!

        var existingProvider= account.storage.copy<Capability<auth(FIND.Leasee) &FIND.LeaseCollection>>(from: providerStoragePath) 
        if existingProvider==nil {
            existingProvider=account.capabilities.storage.issue<auth(FIND.Leasee) &FIND.LeaseCollection>(FIND.LeaseStoragePath) 
            account.storage.save(existingProvider!, to: providerStoragePath)
        }
        var cap = existingProvider!
        self.pointer= FindLeaseMarket.AuthLeasePointer(cap: cap, name: leaseName)
    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        self.saleItems.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})
    }

}

