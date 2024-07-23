import "Profile"
import "FindMarket"
import "FungibleToken"
import "FTRegistry"
import "FIND"
import "FindLeaseMarket"
import "FindLeaseMarketDirectOfferSoft"

transaction(leaseName: String, ftAliasOrIdentifier:String, amount: UFix64, validUntil: UFix64?) {

    let bidsReference: &FindLeaseMarketDirectOfferSoft.MarketBidCollection?
    let ftVaultType: Type

    prepare(account: auth(StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {


        let resolveAddress = FIND.resolve(leaseName)
        if resolveAddress == nil {panic("The address input is not a valid name nor address. Input : ".concat(leaseName))}
        let address = resolveAddress!

        let ft = FTRegistry.getFTInfo(ftAliasOrIdentifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(ftAliasOrIdentifier))

        self.ftVaultType = ft.type

        let walletReference = account.storage.borrow<&{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
        assert(walletReference.balance > amount , message: "Bidder has to have enough balance in wallet")

        let leaseMarketplace = FindMarket.getFindTenantAddress()
        let leaseTenantCapability= FindMarket.getTenantCapability(leaseMarketplace)!
        let leaseTenant = leaseTenantCapability.borrow()!

        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)!
        let leaseDOSBidType= Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>()
        let leaseDOSBidPublicPath=leaseTenant.getPublicPath(leaseDOSBidType)
        let leaseDOSBidStoragePath= leaseTenant.getStoragePath(leaseDOSBidType)
        let leaseDOSBidCap= account.getCapability<&FindLeaseMarketDirectOfferSoft.MarketBidCollection>(leaseDOSBidPublicPath)
        if !leaseDOSBidCap.check() {
            account.storage.save<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOSBidStoragePath)
            account.link<&FindLeaseMarketDirectOfferSoft.MarketBidCollection>(leaseDOSBidPublicPath, target: leaseDOSBidStoragePath)
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
