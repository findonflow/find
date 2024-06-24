import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "FIND"
import "Dandy"
import "Profile"
import "FindMarket"
import "FindMarketDirectOfferSoft"
import "DapperUtilityCoin"
import "FlowUtilityToken"
import "FindLeaseMarketDirectOfferSoft"
import "FindLeaseMarket"
import "TokenForwarding"
import "FindViews"

transaction(name: String) {
    prepare(account: auth(Profile.Admin, StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {
        let leaseCollection = account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
        if !leaseCollection.check() {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let leaseCollectionCap = account.capabilities.storage.issue<&FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(leaseCollectionCap, at: FIND.LeasePublicPath)
        }

        let dandyCap= account.capabilities.get<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
        if !dandyCap.check() {
            account.storage.save<@{NonFungibleToken.Collection}>(<- Dandy.createEmptyCollection(nftType:Type<@Dandy.NFT>()), to: Dandy.CollectionStoragePath)
            let dandyCollectionCap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(Dandy.CollectionStoragePath)
            account.capabilities.publish(dandyCollectionCap, at: Dandy.CollectionPublicPath) 
        }

        var created=false
        var updated=false
        let profileCap = account.capabilities.get<&{Profile.Public}>(Profile.publicPath)
        if !profileCap.check() {
            let profile <-Profile.createUser(name:name, createdAt: "find")
            account.storage.save(<-profile, to: Profile.storagePath)
            let profileCap = account.capabilities.storage.issue<&{Profile.Public}>(Profile.storagePath)
            account.capabilities.publish(profileCap, at: Profile.publicPath)
            let receiverCap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(Profile.storagePath)
            account.capabilities.publish(receiverCap, at: Profile.publicReceiverPath)
            created=true
        }

        let profile=account.storage.borrow<auth(Profile.Admin) &Profile.User>(from: Profile.storagePath)!

        let dapper=getAccount(FindViews.getDapperAddress())

        if !profile.hasWallet("DUC") {
            var ducReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
            var ducBalanceCap = account.capabilities.get<&{FungibleToken.Vault}>(/public/dapperUtilityCoinVault)
            profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance: ducBalanceCap, accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapperUtilityCoin","dapper"]))
            updated=true
        }

        if !profile.hasWallet("FUT") {
            var futReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
            var futBalanceCap = account.capabilities.get<&{FungibleToken.Vault}>(/public/flowUtilityTokenBalance)
            if !futReceiver.check() {
                // Create a new Forwarder resource for FUT and store it in the new account's storage
                let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver))
                account.storage.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)
                futReceiver = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/flowUtilityTokenReceiver)
                account.capabilities.publish(futReceiver, at: /public/flowUtilityTokenReceiver)
            }
            if !futBalanceCap.check() {
                futBalanceCap = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/flowUtilityTokenVault)
                account.capabilities.publish(futBalanceCap, at: /public/flowUtilityTokenBalance)
            }
            profile.addWallet(Profile.Wallet( name:"FUT", receiver:futReceiver, balance:futBalanceCap, accept: Type<@FlowUtilityToken.Vault>(), tags: ["fut", "flowUtilityToken","dapper"]))
            updated=true
        }

        profile.emitCreatedEvent()

        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!

        let tenant = tenantCapability.borrow()!

        let dosSaleType= Type<@FindMarketDirectOfferSoft.SaleItemCollection>()
        let dosSalePublicPath=FindMarket.getPublicPath(dosSaleType, name: tenant.name)
        let dosSaleStoragePath= FindMarket.getStoragePath(dosSaleType, name:tenant.name)
        let dosSaleCap= account.capabilities.get<&FindMarketDirectOfferSoft.SaleItemCollection>(dosSalePublicPath)
        if !dosSaleCap.check() {
            account.storage.save<@FindMarketDirectOfferSoft.SaleItemCollection>(<- FindMarketDirectOfferSoft.createEmptySaleItemCollection(tenantCapability), to: dosSaleStoragePath)
            let dosSaleCap= account.capabilities.storage.issue<&FindMarketDirectOfferSoft.SaleItemCollection>(dosSaleStoragePath)
            account.capabilities.publish(dosSaleCap, at: dosSalePublicPath)
        }

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
