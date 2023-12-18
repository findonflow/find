import FindMarket from 0x097bafa4e0b48eef
import FIND from 0x097bafa4e0b48eef
import FTRegistry from 0x097bafa4e0b48eef
import FindLeaseMarketSale from 0x097bafa4e0b48eef
import FindLeaseMarket from 0x097bafa4e0b48eef

transaction(leaseName: String, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

    let saleItems : &FindLeaseMarketSale.SaleItemCollection?
    let pointer : FindLeaseMarket.AuthLeasePointer
    let vaultType : Type

    prepare(account: auth(BorrowValue) &Account) {

        // Get the salesItemRef from tenant
        let leaseMarketplace = FindMarket.getFindTenantAddress()
        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
        let leaseTenant = leaseTenantCapability.borrow()!

        let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
        let leasePublicPath=leaseTenant.getPublicPath(leaseSaleItemType)
        let leaseStoragePath= leaseTenant.getStoragePath(leaseSaleItemType)
        let leaseSaleItemCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)
        if !leaseSaleItemCap.check() {
            //The link here has to be a capability not a tenant, because it can change.
            account.storage.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
            account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
        }

        self.saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: leaseStoragePath)!

        // Get supported NFT and FT Information from Registries from input alias
        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
        self.vaultType= ft.type

        let ref=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)!

        self.pointer= FindLeaseMarket.AuthLeasePointer(ref: ref, name: leaseName)
    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})

    }

}
