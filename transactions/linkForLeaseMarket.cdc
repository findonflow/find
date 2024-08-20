import "FindLeaseMarketDirectOfferSoft"
import "FindMarket"

transaction() {
    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {
        let leaseTenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!
        let leaseTenant = leaseTenantCapability.borrow()!

        let leaseDOSSaleItemType= Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()
        let leaseDOSPublicPath=leaseTenant.getPublicPath(leaseDOSSaleItemType)
        let leaseDOSStoragePath= leaseTenant.getStoragePath(leaseDOSSaleItemType)
        let leaseDOSSaleItemCap= account.capabilities.get<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(leaseDOSPublicPath)
        if !leaseDOSSaleItemCap.check() {
            //The link here has to be a capability not a tenant, because it can change.
            account.storage.save<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseDOSStoragePath)
            let leaseDOSSaleItemCap = account.capabilities.storage.issue<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(leaseDOSStoragePath)
            account.capabilities.publish(leaseDOSSaleItemCap, at: leaseDOSPublicPath)
        }
    }
}
