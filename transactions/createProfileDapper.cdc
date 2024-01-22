import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Dandy from "../contracts/Dandy.cdc"
import Profile from "../contracts/Profile.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(name: String) {
    prepare(account: auth(Profile.Owner, StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {
        let leaseCollection = account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
        if leaseCollection == nil {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let leaseCollectionCap = account.capabilities.storage.issue<&FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(leaseCollectionCap, at: FIND.LeasePublicPath)
        }

        let dandyCap= account.capabilities.get<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
        if dandyCap == nil {
            account.storage.save<@{NonFungibleToken.Collection}>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
            let dandyCollectionCap = account.capabilities.storage.issue<&{NonFungibleToken.Collection}>(Dandy.CollectionStoragePath)
            account.capabilities.publish(dandyCollectionCap, at: Dandy.CollectionPublicPath) 
        }

        var created=false
        var updated=false
        let profileCap = account.capabilities.get<&{Profile.Public}>(Profile.publicPath)
        if profileCap == nil {
            let profile <-Profile.createUser(name:name, createdAt: "find")
            account.storage.save(<-profile, to: Profile.storagePath)
            let profileCap = account.capabilities.storage.issue<&{Profile.Public}>(Profile.storagePath)
            account.capabilities.publish(profileCap, at: Profile.publicPath)
            let receiverCap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(Profile.storagePath)
            account.capabilities.publish(receiverCap, at: Profile.publicReceiverPath)
            created=true
        }

        let profile=account.storage.borrow<auth(Profile.Owner) &Profile.User>(from: Profile.storagePath)!

        if !profile.hasWallet("DUC") {
            let ducReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!
            profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/dapperUtilityCoinVault)!, accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapperUtilityCoin","dapper"]))
            updated=true
        }

        if !profile.hasWallet("FUT") {
            let futReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!
            profile.addWallet(Profile.Wallet( name:"FUT", receiver:futReceiver, balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/flowUtilityTokenVault)!, accept: Type<@FlowUtilityToken.Vault>(), tags: ["fut", "flowUtilityToken","dapper"]))
            updated=true
        }

        profile.emitCreatedEvent()

        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!

        let tenant = tenantCapability.borrow()!

        /*
        let dosSaleType= Type<@FindMarketDirectOfferSoft.SaleItemCollection>()
        let dosSalePublicPath=FindMarket.getPublicPath(dosSaleType, name: tenant.name)
        let dosSaleStoragePath= FindMarket.getStoragePath(dosSaleType, name:tenant.name)
        let dosSaleCap= account.capabilities.get<&FindMarketDirectOfferSoft.SaleItemCollection>(dosSalePublicPath)
        if dosSaleCap == nil {
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
        if leaseDOSSaleItemCap == nil {
            //The link here has to be a capability not a tenant, because it can change.
            account.storage.save<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseDOSStoragePath)
            let leaseDOSSaleItemCap = account.capabilities.storage.issue<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(leaseDOSStoragePath)
            account.capabilities.publish(leaseDOSSaleItemCap, at: leaseDOSPublicPath)
        }

        */
    }
}
