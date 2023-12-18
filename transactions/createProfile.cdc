import "FungibleToken"
import "NonFungibleToken"
import "FUSD"
//import "FiatToken"
import "FlowToken"
import "MetadataViews"
import "FIND"
import "FindPack"
import "Profile"
//import "FindMarket"
//import "FindMarketDirectOfferEscrow"
//import "Dandy"
//import "FindThoughts"

transaction(name: String) {
    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {
        //if we do not have a profile it might be stored under a different address so we will just remove it
        let profileCapFirst = account.capabilities.get<&{Profile.Public}>(Profile.publicPath)
        if profileCapFirst != nil {
            return 
        }

        //the code below has some dead code for this specific transaction, but it is hard to maintain otherwise
        //SYNC with register
        //Add exising FUSD or create a new one and add it
        let fusdReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if fusdReceiver == nil {
            let fusd <- FUSD.createEmptyVault()

            account.storage.save(<- fusd, to: /storage/fusdVault)
            var cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/fusdVault)
            account.capabilities.publish(cap, at: /public/fusdReceiver)
            let capb = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/fusdVault)
            account.capabilities.publish(capb, at: /public/fusdBalance)
        }

        /*
        let usdcCap = account.capabilities.get<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if !usdcCap.check() {
            account.storage.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)

            let cap = account.capabilities.storage.issue<&FiatToken.Vault>(FiatToken.VaultStoragePath)
            account.capabilities.publish(cap, at: FiatToken.VaultUUIDPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultReceiverPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultBalancePubPath)
        }
        */

        let leaseCollection = account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
        if leaseCollection == nil {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let cap = account.capabilities.storage.issue<&FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(cap, at: FIND.LeasePublicPath)
        }

        let bidCollection = account.capabilities.get<&FIND.BidCollection>(FIND.BidPublicPath)
        if bidCollection == nil {

            let fr = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver) ?? panic("could not find balance") 
            let lc = account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
            account.storage.save(<- FIND.createEmptyBidCollection(receiver: fr!, leases: lc!), to: FIND.BidStoragePath)
            let cap = account.capabilities.storage.issue<&FIND.BidCollection>(FIND.BidStoragePath)
            account.capabilities.publish(cap, at: FIND.BidPublicPath)
        }

        /*
        let dandyCap= account.capabilities.get<&{NonFungibleToken.Collection}>(Dandy.CollectionPublicPath)
        if !dandyCap.check() {
            account.storage.save<@NonFungibleToken.Collection>(<- Dandy.createEmptyCollection(), to: Dandy.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&Dandy.Collection>(Dandy.CollectionStoragePath)
            account.capabilities.publish(cap, at: Dandy.CollectionPublicPath)
        }

        let thoughtsCap= account.capabilities.get<&{FindThoughts.CollectionPublic}>(FindThoughts.CollectionPublicPath)
        if !thoughtsCap.check() {
            account.storage.save(<- FindThoughts.createEmptyCollection(), to: FindThoughts.CollectionStoragePath)
            let cap = account.capabilities.storage.issue<&FindThoughts.Collection>(FindThoughts.CollectionStoragePath)
            account.capabilities.publish(cap, at: FindThoughts.CollectionPublicPath)
        }
        */

        let findPackCap= account.capabilities.get<&{NonFungibleToken.Collection}>(FindPack.CollectionPublicPath)
        if findPackCap == nil {
            account.storage.save( <- FindPack.createEmptyCollection(), to: FindPack.CollectionStoragePath)

            let cap = account.capabilities.storage.issue<&FindPack.Collection>(FindPack.CollectionStoragePath)
            account.capabilities.publish(cap, at: FindPack.CollectionPublicPath)
        }

        var created=false
        var updated=false
        let profileCap = account.capabilities.get<&Profile.User>(Profile.publicPath)
        if profileCap == nil{
            let newProfile <-Profile.createUser(name:name, createdAt: "find")
            account.storage.save(<-newProfile, to: Profile.storagePath)

            let cap = account.capabilities.storage.issue<&Profile.User>(Profile.storagePath)
            account.capabilities.publish(cap, at: Profile.publicPath)
            account.capabilities.publish(cap, at: Profile.publicReceiverPath)
            created=true
        }

        let profile=account.storage.borrow<&Profile.User>(from: Profile.storagePath)!

        if !profile.hasWallet("Flow") {
            let flowWallet=Profile.Wallet( name:"Flow", receiver:account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!, balance:account.capabilities.get<&{FungibleToken.Vault}>(/public/flowTokenBalance)!, accept: Type<@FlowToken.Vault>(), tags: ["flow"])

            profile.addWallet(flowWallet)
            updated=true
        }
        if !profile.hasWallet("FUSD") {
            let fr = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver) ?? panic("could not find balance") 
            let fb =account.capabilities.get<&{FungibleToken.Vault}>(/public/fusdBalance) ?? panic("could not find balance") 
            profile.addWallet(Profile.Wallet( name:"FUSD", receiver:fr, balance:fb, accept: Type<@FUSD.Vault>(), tags: ["fusd", "stablecoin"]))
            updated=true
        }

        /*
        if !profile.hasWallet("USDC") {
            profile.addWallet(Profile.Wallet( name:"USDC", receiver:usdcCap, balance:account.capabilities.get<&{FungibleToken.Balance}>(FiatToken.VaultBalancePubPath), accept: Type<@FiatToken.Vault>(), tags: ["usdc", "stablecoin"]))
            updated=true
        }
        */

        //If find name not set and we have a profile set it.
        if profile.getFindName() == "" {
            if let findName = FIND.reverseLookup(account.address) {
                profile.setFindName(findName)
                // If name is set, it will emit Updated Event, there is no need to emit another update event below. 
                updated=false
            }
        }

        if created {
            profile.emitCreatedEvent()
        } else if updated {
            profile.emitUpdatedEvent()
        }

        /*
        let receiverCap=account.capabilities.get<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
        let tenantCapability= FindMarket.getTenantCapability(FindMarket.getFindTenantAddress())!

        let tenant = tenantCapability.borrow()!

        let doeSaleType= Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()
        let doeSalePublicPath=FindMarket.getPublicPath(doeSaleType, name: tenant.name)
        let doeSaleStoragePath= FindMarket.getStoragePath(doeSaleType, name:tenant.name)
        let doeSaleCap= account.capabilities.get<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath) 
        if !doeSaleCap.check() {
            account.storage.save<@FindMarketDirectOfferEscrow.SaleItemCollection>(<- FindMarketDirectOfferEscrow.createEmptySaleItemCollection(tenantCapability), to: doeSaleStoragePath)
            account.link<&FindMarketDirectOfferEscrow.SaleItemCollection{FindMarketDirectOfferEscrow.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(doeSalePublicPath, target: doeSaleStoragePath)
        }
        //SYNC with register
        */

    }
}
