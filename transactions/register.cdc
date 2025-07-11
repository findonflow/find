import "FlowToken"
import "FIND"
import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "FindPack"
import "Profile"
import "FindMarket"
import "FindMarketDirectOfferEscrow"
import "FindLeaseMarketDirectOfferSoft"
import "FindLeaseMarket"
import "Dandy"


transaction(name: String, maxAmount: UFix64) {

    let vaultRef : auth(FungibleToken.Withdraw) &FlowToken.Vault?
    let leases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?
    let cost : UFix64

    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {

        //the code below has some dead code for this specific transaction, but it is hard to maintain otherwise
        //SYNC with register
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
            let newProfile <-Profile.createUser(name:name, createdAt: "find")
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

        self.vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
        self.leases=account.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from: FIND.LeaseStoragePath)

        self.cost = FIND.calculateCostInFlow(name)

    }


    pre{
        self.cost <= maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.leases != nil : "Could not borrow reference to find lease collection"
        self.vaultRef!.balance > self.cost : "Balance of vault is not high enough ".concat(self.cost.toString()).concat(" total balance is ").concat(self.vaultRef!.balance.toString())
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        self.leases!.register(name: name, vault: <- payVault)
    }
}
