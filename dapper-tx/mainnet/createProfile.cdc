import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import FlowToken from 0x1654653399040a61
import MetadataViews from 0x1d7e57aa55817448
import FIND from 0x097bafa4e0b48eef
import Dandy from 0x097bafa4e0b48eef
import Profile from 0x097bafa4e0b48eef
import FindMarket from 0x097bafa4e0b48eef
import FindMarketSale from 0x097bafa4e0b48eef
import FindMarketAuctionEscrow from 0x097bafa4e0b48eef
import FindMarketAuctionSoft from 0x097bafa4e0b48eef
import FindMarketDirectOfferEscrow from 0x097bafa4e0b48eef
import FindMarketDirectOfferSoft from 0x097bafa4e0b48eef
import DapperUtilityCoin from 0xead892083b3e2c6c
import FlowUtilityToken from 0xead892083b3e2c6c 
import TokenForwarding from 0xe544175ee0461c4b
import FindLeaseMarketSale from 0x097bafa4e0b48eef
import FindLeaseMarketAuctionSoft from 0x097bafa4e0b48eef
// import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"
import FindLeaseMarketDirectOfferSoft from 0x097bafa4e0b48eef
// import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"
import FindLeaseMarket from 0x097bafa4e0b48eef


transaction(name: String) {
    prepare(dapper: AuthAccount, account: AuthAccount) {
        let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
        if !leaseCollection.check() {
            account.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
        }

        let dandyCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Dandy.CollectionPublicPath)
        if !dandyCap.check() {
            account.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
            account.link<&Dandy.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
                Dandy.CollectionPublicPath,
                target: Dandy.CollectionStoragePath
            )
            account.link<&Dandy.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection, Dandy.CollectionPublic}>(
                Dandy.CollectionPrivatePath,
                target: Dandy.CollectionStoragePath
            )
        }

        let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        if !ducReceiver.check() {
            // Create a new Forwarder resource for DUC and store it in the new account's storage
            let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
            account.save(<-ducForwarder, to: /storage/dapperUtilityCoinVault)
            // Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
            account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
        }

        let futReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        if !futReceiver.check() {
            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
            account.save(<-futForwarder, to: /storage/flowUtilityTokenVault)
            // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
            account.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver,target: /storage/flowUtilityTokenVault)
        }

        var created=false
        var updated=false
        let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
        if !profileCap.check() {
            let profile <-Profile.createUser(name:name, createdAt: "find")
            account.save(<-profile, to: Profile.storagePath)
            account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
            account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
            created=true
        }

        let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!

        if !profile.hasWallet("DUC") {
            let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
            profile.addWallet(Profile.Wallet( name:"DUC", receiver:ducReceiver, balance:dapper.getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapperUtilityCoin","dapper"]))
            updated=true
        }

        if !profile.hasWallet("FUT") {
            let futReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
            profile.addWallet(Profile.Wallet( name:"FUT", receiver:futReceiver, balance:dapper.getCapability<&{FungibleToken.Balance}>(/public/flowUtilityTokenBalance), accept: Type<@FlowUtilityToken.Vault>(), tags: ["fut", "flowUtilityToken","dapper"]))
            updated=true
        }

        profile.emitCreatedEvent()


        let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let saleItemType= Type<@FindMarketSale.SaleItemCollection>()
        let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!

        let tenant = tenantCapability.borrow()!
        let publicPath=FindMarket.getPublicPath(saleItemType, name: tenant.name)
        let storagePath= FindMarket.getStoragePath(saleItemType, name:tenant.name)

        let saleItemCap= account.getCapability<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath) 
        if !saleItemCap.check() {
            //The link here has to be a capability not a tenant, because it can change.
            account.save<@FindMarketSale.SaleItemCollection>(<- FindMarketSale.createEmptySaleItemCollection(tenantCapability), to: storagePath)
            account.link<&FindMarketSale.SaleItemCollection{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(publicPath, target: storagePath)
        }

        let doeSaleType= Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
        let doeSalePublicPath=FindMarket.getPublicPath(doeSaleType, name: tenant.name)
        let doeSaleStoragePath= FindMarket.getStoragePath(doeSaleType, name:tenant.name)
        let doeSaleCap= account.getCapability<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath) 
        if !doeSaleCap.check() {
            account.save<@FindMarketDirectOfferEscrow.SaleItemCollection>(<- FindMarketDirectOfferEscrow.createEmptySaleItemCollection(tenantCapability), to: doeSaleStoragePath)
            account.link<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath, target: doeSaleStoragePath)
        }

        let doeBidType= Type<@FindMarketDirectOfferEscrow.MarketBidCollection>()
        let doeBidPublicPath=FindMarket.getPublicPath(doeBidType, name: tenant.name)
        let doeBidStoragePath= FindMarket.getStoragePath(doeBidType, name:tenant.name)
        let doeBidCap= account.getCapability<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath) 
        if !doeBidCap.check() {
            account.save<@FindMarketDirectOfferEscrow.MarketBidCollection>(<- FindMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: doeBidStoragePath)
            account.link<&FindMarketDirectOfferEscrow.MarketBidCollection{FindMarketDirectOfferEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(doeBidPublicPath, target: doeBidStoragePath)
        }

        /// auctions that escrow ft
        let aeSaleType= Type<@FindMarketAuctionEscrow.SaleItemCollection>()
        let aeSalePublicPath=FindMarket.getPublicPath(aeSaleType, name: tenant.name)
        let aeSaleStoragePath= FindMarket.getStoragePath(aeSaleType, name:tenant.name)
        let aeSaleCap= account.getCapability<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSalePublicPath) 
        if !aeSaleCap.check() {
            account.save<@FindMarketAuctionEscrow.SaleItemCollection>(<- FindMarketAuctionEscrow.createEmptySaleItemCollection(tenantCapability), to: aeSaleStoragePath)
            account.link<&FindMarketAuctionEscrow.SaleItemCollection{FindMarketAuctionEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(aeSalePublicPath, target: aeSaleStoragePath)
        }

        let dosSaleType= Type<@FindMarketDirectOfferSoft.SaleItemCollection>()

        let dosSalePublicPath=FindMarket.getPublicPath(dosSaleType, name: tenant.name)
        let dosSaleStoragePath= FindMarket.getStoragePath(dosSaleType, name:tenant.name)

        let dosSaleCap= account.getCapability<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath) 
        if !dosSaleCap.check() {
            account.save<@FindMarketDirectOfferSoft.SaleItemCollection>(<- FindMarketDirectOfferSoft.createEmptySaleItemCollection(tenantCapability), to: dosSaleStoragePath)
            account.link<&FindMarketDirectOfferSoft.SaleItemCollection{FindMarketDirectOfferSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(dosSalePublicPath, target: dosSaleStoragePath)
        }

        let dosBidType= Type<@FindMarketDirectOfferSoft.MarketBidCollection>()
        let dosBidPublicPath=FindMarket.getPublicPath(dosBidType, name: tenant.name)
        let dosBidStoragePath= FindMarket.getStoragePath(dosBidType, name:tenant.name)
        let dosBidCap= account.getCapability<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath) 
        if !dosBidCap.check() {
            account.save<@FindMarketDirectOfferSoft.MarketBidCollection>(<- FindMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: dosBidStoragePath)
            account.link<&FindMarketDirectOfferSoft.MarketBidCollection{FindMarketDirectOfferSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(dosBidPublicPath, target: dosBidStoragePath)
        }

        let aeBidType= Type<@FindMarketAuctionEscrow.MarketBidCollection>()

        let aeBidPublicPath=FindMarket.getPublicPath(aeBidType, name: tenant.name)
        let aeBidStoragePath= FindMarket.getStoragePath(aeBidType, name:tenant.name)
        let aeBidCap= account.getCapability<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath) 
        if !aeBidCap.check() {
            account.save<@FindMarketAuctionEscrow.MarketBidCollection>(<- FindMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: aeBidStoragePath)
            account.link<&FindMarketAuctionEscrow.MarketBidCollection{FindMarketAuctionEscrow.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(aeBidPublicPath, target: aeBidStoragePath)
        }

     /// auctions that refers FT so 'soft' auction
        let asSaleType= Type<@FindMarketAuctionSoft.SaleItemCollection>()
        let asSalePublicPath=FindMarket.getPublicPath(asSaleType, name: tenant.name)
        let asSaleStoragePath= FindMarket.getStoragePath(asSaleType, name:tenant.name)
        let asSaleCap= account.getCapability<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(asSalePublicPath) 
        if !asSaleCap.check() {
            account.save<@FindMarketAuctionSoft.SaleItemCollection>(<- FindMarketAuctionSoft.createEmptySaleItemCollection(tenantCapability), to: asSaleStoragePath)
            account.link<&FindMarketAuctionSoft.SaleItemCollection{FindMarketAuctionSoft.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(asSalePublicPath, target: asSaleStoragePath)
        }

        let asBidType= Type<@FindMarketAuctionSoft.MarketBidCollection>()
        let asBidPublicPath=FindMarket.getPublicPath(asBidType, name: tenant.name)
        let asBidStoragePath= FindMarket.getStoragePath(asBidType, name:tenant.name)
        let asBidCap= account.getCapability<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(asBidPublicPath) 
        if !asBidCap.check() {
            account.save<@FindMarketAuctionSoft.MarketBidCollection>(<- FindMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:tenantCapability), to: asBidStoragePath)
            account.link<&FindMarketAuctionSoft.MarketBidCollection{FindMarketAuctionSoft.MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(asBidPublicPath, target: asBidStoragePath)
        }

        let leaseTenantCapability= FindMarket.getTenantCapability(FindMarket.getTenantAddress("findLease")!)!

        let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
        let leasePublicPath=FindMarket.getPublicPath(leaseSaleItemType, name: "findLease")
        let leaseStoragePath= FindMarket.getStoragePath(leaseSaleItemType, name:"findLease")
        let leaseSaleItemCap= account.getCapability<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath) 
        if !leaseSaleItemCap.check() {
            //The link here has to be a capability not a tenant, because it can change.
            account.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
            account.link<&FindLeaseMarketSale.SaleItemCollection{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath, target: leaseStoragePath)
        }

        let leaseASSaleItemType= Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>()
        let leaseASPublicPath=FindMarket.getPublicPath(leaseASSaleItemType, name: "findLease")
        let leaseASStoragePath= FindMarket.getStoragePath(leaseASSaleItemType, name:"findLease")
        let leaseASSaleItemCap= account.getCapability<&FindLeaseMarketAuctionSoft.SaleItemCollection{FindLeaseMarketAuctionSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseASPublicPath) 
        if !leaseASSaleItemCap.check() {
            //The link here has to be a capability not a tenant, because it can change.
            account.save<@FindLeaseMarketAuctionSoft.SaleItemCollection>(<- FindLeaseMarketAuctionSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseASStoragePath)
            account.link<&FindLeaseMarketAuctionSoft.SaleItemCollection{FindLeaseMarketAuctionSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseASPublicPath, target: leaseASStoragePath)
        }


        let leaseASBidType= Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>()
        let leaseASBidPublicPath=FindMarket.getPublicPath(leaseASBidType, name: "findLease")
        let leaseASBidStoragePath= FindMarket.getStoragePath(leaseASBidType, name: "findLease")
        let leaseASBidCap= account.getCapability<&FindLeaseMarketAuctionSoft.MarketBidCollection{FindLeaseMarketAuctionSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath) 
        if !leaseASBidCap.check() {
            account.save<@FindLeaseMarketAuctionSoft.MarketBidCollection>(<- FindLeaseMarketAuctionSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseASBidStoragePath)
            account.link<&FindLeaseMarketAuctionSoft.MarketBidCollection{FindLeaseMarketAuctionSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseASBidPublicPath, target: leaseASBidStoragePath)
        }

        // let leaseAESaleItemType= Type<@FindLeaseMarketAuctionEscrow.SaleItemCollection>()
        // let leaseAEPublicPath=FindMarket.getPublicPath(leaseAESaleItemType, name: "findLease")
        // let leaseAEStoragePath= FindMarket.getStoragePath(leaseAESaleItemType, name:"findLease")
        // let leaseAESaleItemCap= account.getCapability<&FindLeaseMarketAuctionEscrow.SaleItemCollection{FindLeaseMarketAuctionEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseAEPublicPath) 
        // if !leaseAESaleItemCap.check() {
        //     //The link here has to be a capability not a tenant, because it can change.
        //     account.save<@FindLeaseMarketAuctionEscrow.SaleItemCollection>(<- FindLeaseMarketAuctionEscrow.createEmptySaleItemCollection(leaseTenantCapability), to: leaseAEStoragePath)
        //     account.link<&FindLeaseMarketAuctionEscrow.SaleItemCollection{FindLeaseMarketAuctionEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseAEPublicPath, target: leaseAEStoragePath)
        // }

        // let leaseAEBidType= Type<@FindLeaseMarketAuctionEscrow.MarketBidCollection>()
        // let leaseAEBidPublicPath=FindMarket.getPublicPath(leaseAEBidType, name: "findLease")
        // let leaseAEBidStoragePath= FindMarket.getStoragePath(leaseAEBidType, name: "findLease")
        // let leaseAEBidCap= account.getCapability<&FindLeaseMarketAuctionEscrow.MarketBidCollection{FindLeaseMarketAuctionEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseAEBidPublicPath) 
        // if !leaseAEBidCap.check() {
        //     account.save<@FindLeaseMarketAuctionEscrow.MarketBidCollection>(<- FindLeaseMarketAuctionEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseAEBidStoragePath)
        //     account.link<&FindLeaseMarketAuctionEscrow.MarketBidCollection{FindLeaseMarketAuctionEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseAEBidPublicPath, target: leaseAEBidStoragePath)
        // }

        let leaseDOSSaleItemType= Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()
        let leaseDOSPublicPath=FindMarket.getPublicPath(leaseDOSSaleItemType, name: "findLease")
        let leaseDOSStoragePath= FindMarket.getStoragePath(leaseDOSSaleItemType, name:"findLease")
        let leaseDOSSaleItemCap= account.getCapability<&FindLeaseMarketDirectOfferSoft.SaleItemCollection{FindLeaseMarketDirectOfferSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOSPublicPath) 
        if !leaseDOSSaleItemCap.check() {
            //The link here has to be a capability not a tenant, because it can change.
            account.save<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptySaleItemCollection(leaseTenantCapability), to: leaseDOSStoragePath)
            account.link<&FindLeaseMarketDirectOfferSoft.SaleItemCollection{FindLeaseMarketDirectOfferSoft.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOSPublicPath, target: leaseDOSStoragePath)
        }

        let leaseDOSBidType= Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>()
        let leaseDOSBidPublicPath=FindMarket.getPublicPath(leaseDOSBidType, name: "findLease")
        let leaseDOSBidStoragePath= FindMarket.getStoragePath(leaseDOSBidType, name: "findLease")
        let leaseDOSBidCap= account.getCapability<&FindLeaseMarketDirectOfferSoft.MarketBidCollection{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath) 
        if !leaseDOSBidCap.check() {
            account.save<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>(<- FindLeaseMarketDirectOfferSoft.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOSBidStoragePath)
            account.link<&FindLeaseMarketDirectOfferSoft.MarketBidCollection{FindLeaseMarketDirectOfferSoft.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOSBidPublicPath, target: leaseDOSBidStoragePath)
        }

        // let leaseDOESaleItemType= Type<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>()
        // let leaseDOEPublicPath=FindMarket.getPublicPath(leaseDOESaleItemType, name: "findLease")
        // let leaseDOEStoragePath= FindMarket.getStoragePath(leaseDOESaleItemType, name:"findLease")
        // let leaseDOESaleItemCap= account.getCapability<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection{FindLeaseMarketDirectOfferEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOEPublicPath) 
        // if !leaseDOESaleItemCap.check() {
        //     //The link here has to be a capability not a tenant, because it can change.
        //     account.save<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>(<- FindLeaseMarketDirectOfferEscrow.createEmptySaleItemCollection(leaseTenantCapability), to: leaseDOEStoragePath)
        //     account.link<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection{FindLeaseMarketDirectOfferEscrow.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leaseDOEPublicPath, target: leaseDOEStoragePath)
        // }

        // let leaseDOEBidType= Type<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>()
        // let leaseDOEBidPublicPath=FindMarket.getPublicPath(leaseDOEBidType, name: "findLease")
        // let leaseDOEBidStoragePath= FindMarket.getStoragePath(leaseDOEBidType, name: "findLease")
        // let leaseDOEBidCap= account.getCapability<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection{FindLeaseMarketDirectOfferEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOEBidPublicPath) 
        // if !leaseDOEBidCap.check() {
        //     account.save<@FindLeaseMarketDirectOfferEscrow.MarketBidCollection>(<- FindLeaseMarketDirectOfferEscrow.createEmptyMarketBidCollection(receiver:receiverCap, tenantCapability:leaseTenantCapability), to: leaseDOEBidStoragePath)
        //     account.link<&FindLeaseMarketDirectOfferEscrow.MarketBidCollection{FindLeaseMarketDirectOfferEscrow.MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(leaseDOEBidPublicPath, target: leaseDOEBidStoragePath)
        // }
        //SYNC with register
    }
}