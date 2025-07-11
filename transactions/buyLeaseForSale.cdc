import "FindMarket"
import "FTRegistry"
import "FungibleToken"
import "NonFungibleToken"
import "FIND"
import "Profile"
import "FindLeaseMarketSale"
import "FindLeaseMarketDirectOfferSoft"
import "FindMarketDirectOfferEscrow"
import "FindLeaseMarket"
import "Dandy"
import "FindPack"
import "FlowToken"

transaction(leaseName: String, amount: UFix64) {

    let buyer : Address
    let walletReference : auth(FungibleToken.Withdraw) &{FungibleToken.Vault}

    let saleItemCollection: &{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}

    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {

        let leaseCollection = account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
        if !leaseCollection.check() {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let cap = account.capabilities.storage.issue<&FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(cap, at: FIND.LeasePublicPath)
        }

        let dandyCap= account.capabilities.get<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
        if !dandyCap.check() {
            account.storage.save(<- Dandy.createEmptyCollection(nftType:Type<@Dandy.NFT>()), to: Dandy.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&Dandy.Collection>(Dandy.CollectionStoragePath)
            account.capabilities.publish(cap, at: Dandy.CollectionPublicPath)
        }

        let findPackCap= account.capabilities.get<&{NonFungibleToken.Collection}>(FindPack.CollectionPublicPath)
        if !findPackCap.check() {
            account.storage.save( <- FindPack.createEmptyCollection(nftType: Type<@FindPack.NFT>()), to: FindPack.CollectionStoragePath)

            let cap = account.capabilities.storage.issue<&FindPack.Collection>(FindPack.CollectionStoragePath)
            account.capabilities.publish(cap, at: FindPack.CollectionPublicPath)
        }

        var created=false
        var updated=false
        let profileCap = account.capabilities.get<&Profile.User>(Profile.publicPath)
        if !profileCap.check(){
            let newProfile <-Profile.createUser(name:leaseName, createdAt: "find")
            account.storage.save(<-newProfile, to: Profile.storagePath)

            let cap = account.capabilities.storage.issue<&Profile.User>(Profile.storagePath)
            account.capabilities.publish(cap, at: Profile.publicPath)
            account.capabilities.publish(cap, at: Profile.publicReceiverPath)
            created=true
        }

        let profile=account.storage.borrow<auth(Profile.Admin) &Profile.User>(from: Profile.storagePath)!

        if !profile.hasWallet("Flow") {
            let flowWallet=Profile.Wallet( name:"Flow", receiver:account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenBalance), accept: Type<@FlowToken.Vault>(), tags: ["flow"])

            profile.addWallet(flowWallet)
            updated=true
        }

        if created {
            profile.emitCreatedEvent()
        } else if updated {
            profile.emitUpdatedEvent()
        }


        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!

        let tenant = tenantCapability.borrow()!

        let doeSaleType= Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
        let doeSalePublicPath=FindMarket.getPublicPath(doeSaleType, name: tenant.name)
        let doeSaleStoragePath= FindMarket.getStoragePath(doeSaleType, name:tenant.name)
        let doeSaleCap= account.capabilities.get<&{FindMarketDirectOfferEscrow.SaleItemCollectionPublic}>(doeSalePublicPath) 
        if !doeSaleCap.check() {
            account.storage.save<@FindMarketDirectOfferEscrow.SaleItemCollection>(<- FindMarketDirectOfferEscrow.createEmptySaleItemCollection(tenantCapability), to: doeSaleStoragePath)
            let cap = account.capabilities.storage.issue<&{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSaleStoragePath)
            account.capabilities.publish(cap, at: doeSalePublicPath)
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
        let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))

        if address == nil {
            panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
        }

        let leaseMarketplace = FindMarket.getTenantAddress("find") ?? panic("Cannot find find tenant")
        let saleItemsCap= FindLeaseMarketSale.getSaleItemCapability(marketplace: leaseMarketplace, user:address) ?? panic("cannot find sale item cap for find")

        let leaseSaleItemType= Type<@FindLeaseMarketSale.SaleItemCollection>()
        let leasePublicPath=FindMarket.getPublicPath(leaseSaleItemType, name: "find")
        let leaseStoragePath= FindMarket.getStoragePath(leaseSaleItemType, name:"find")
        var leaseSaleItemCap= account.capabilities.get<&{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(leasePublicPath)
        if !leaseSaleItemCap.check(){
            //The link here has to be a capability not a tenant, because it can change.
            account.storage.save<@FindLeaseMarketSale.SaleItemCollection>(<- FindLeaseMarketSale.createEmptySaleItemCollection(leaseTenantCapability), to: leaseStoragePath)
            leaseSaleItemCap= account.capabilities.storage.issue<&{FindLeaseMarket.SaleItemCollectionPublic, FindLeaseMarketSale.SaleItemCollectionPublic}>(leaseStoragePath)
            account.capabilities.publish(leaseSaleItemCap, at: leasePublicPath)
        }

        self.saleItemCollection = saleItemsCap.borrow()!
        let item = self.saleItemCollection.borrowSaleItem(leaseName)

        let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

        self.walletReference = account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
        self.buyer = account.address
    }

    pre {
        self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
    }

    execute {
        let vault <- self.walletReference.withdraw(amount: amount)
        self.saleItemCollection.buy(name:leaseName, vault: <- vault, to: self.buyer)
    }
}
