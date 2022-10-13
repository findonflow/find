import FindMarket from 0x097bafa4e0b48eef
import DapperUtilityCoin from 0xead892083b3e2c6c
import FIND from 0x097bafa4e0b48eef
import Profile from 0x097bafa4e0b48eef
import FTRegistry from 0x097bafa4e0b48eef
import FindLeaseMarketSale from 0x097bafa4e0b48eef
import FindLeaseMarket from 0x097bafa4e0b48eef

transaction(dapperAddress: Address, leaseName: String, ftAliasOrIdentifier: String, directSellPrice:UFix64, validUntil: UFix64?) {

    let saleItems : &FindLeaseMarketSale.SaleItemCollection?
    let pointer : FindLeaseMarket.AuthLeasePointer
    let vaultType : Type

    prepare(account: AuthAccount) {

        let profile =account.borrow<&Profile.User>(from:Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")

        let leaseTenantCapability= FindMarket.getTenantCapability(FindMarket.getTenantAddress("findLease")!)!
        // Get the salesItemRef from tenant
        let leaseTenant = leaseTenantCapability.borrow()!
        self.saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: leaseTenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>()))

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
