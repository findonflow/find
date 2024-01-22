import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

transaction(leaseName: String, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

    let saleItems : auth(FindLeaseMarketSale.Seller) &FindLeaseMarketSale.SaleItemCollection?
    let pointer : FindLeaseMarket.AuthLeasePointer
    let vaultType : Type

    prepare(account: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {

        // Get the salesItemRef from tenant
        let leaseMarketplace = FindMarket.getFindTenantAddress()
        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
        let leaseTenant = leaseTenantCapability.borrow()!

        let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
        let leasePublicPath=leaseTenant.getPublicPath(leaseSaleItemType)
        let leaseStoragePath= leaseTenant.getStoragePath(leaseSaleItemType)
        let leaseSaleItemCap= account.capabilities.get<&FindLeaseMarketSale.SaleItemCollection>(leasePublicPath)
        if leaseSaleItemCap == nil {
            //The link here has to be a capability not a tenant, because it can change.
            account.storage.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
            let leaseSaleItemCap= account.capabilities.storage.issue<&FindLeaseMarketSale.SaleItemCollection>(leaseStoragePath)
            account.capabilities.publish(leaseSaleItemCap, at: leasePublicPath)
        }

        self.saleItems= account.storage.borrow<auth(FindLeaseMarketSale.Seller) &FindLeaseMarketSale.SaleItemCollection>(from: leaseStoragePath)!

        // Get supported NFT and FT Information from Registries from input alias
        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))
        self.vaultType= ft.type

        //TODO: figure out how to get or save this. init problem
        let cap=account.capabilities.storage.issue<auth(FIND.Leasee) &FIND.LeaseCollection>(FIND.LeaseStoragePath)
        self.pointer= FindLeaseMarket.AuthLeasePointer(cap: cap, name: leaseName)
    }

    pre{
        self.saleItems != nil : "Cannot borrow reference to saleItem"
    }

    execute{
        self.saleItems!.listForSale(pointer: self.pointer, vaultType: self.vaultType, directSellPrice: directSellPrice, validUntil: validUntil, extraField: {})

    }

}

