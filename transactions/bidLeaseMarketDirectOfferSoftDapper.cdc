import "FungibleToken"
import "Profile"
import "FindMarket"
import "FTRegistry"
import "FIND"
import "FindLeaseMarket"
import "FindLeaseMarketDirectOfferSoft"

transaction(leaseName: String, ftAliasOrIdentifier:String, amount: UFix64, validUntil: UFix64?) {

    let bidsReference: &FindLeaseMarketDirectOfferSoft.MarketBidCollection?
    let ftVaultType: Type

    prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue, IssueStorageCapabilityController) &Account) {

        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

        self.ftVaultType = ft.type

        let leaseMarketplace = FindMarket.getFindTenantAddress()
        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
        let leaseTenant = leaseTenantCapability.borrow()!

        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
        let leaseDOSBidType= Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>()
        let leaseDOSBidPublicPath=leaseTenant.getPublicPath(leaseDOSBidType)
        let leaseDOSBidStoragePath= leaseTenant.getStoragePath(leaseDOSBidType)
        let leaseDOSBidCap= account.capabilities.get<&{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath)
        if leaseDOSBidCap == nil {
            account.storage.save<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOSBidStoragePath)
            let cap = account.capabilities.storage.issue<&{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidStoragePath)
            account.capabilities.publish(cap, at: leaseDOSBidPublicPath)
        }

        self.bidsReference= account.storage.borrow<&FindLeaseMarketDirectOfferSoft.MarketBidCollection>(from: leaseDOSBidStoragePath)

    }

    pre {
        self.bidsReference != nil : "This account does not have a bid collection"
    }

    execute {
        self.bidsReference!.bid(name:leaseName, amount: amount, vaultType: self.ftVaultType, validUntil: validUntil, saleItemExtraField: {}, bidExtraField: {})
    }
}
