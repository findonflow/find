import "FLOAT"
import "FLOATVerifiers"
import "NonFungibleToken"
import "MetadataViews"
import "GrantedAccountAccess"

transaction(
    forHost: Address, 
    claimable: Bool, 
    name: String, 
    description: String, 
    image: String, 
    url: String, 
    transferrable: Bool, 
    timelock: Bool, 
    dateStart: UFix64, 
    timePeriod: UFix64, 
    secret: Bool, 
    secrets: [String], 
    limited: Bool, 
    capacity: UInt64, 
    initialGroups: [String], 
    flowTokenPurchase: Bool, 
    flowTokenCost: UFix64
) {

    let FLOATEvents: &FLOAT.FLOATEvents

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {
        let col= account.storage.borrow<&FLOAT.Collection>(from: FLOAT.FLOATCollectionStoragePath)
        if col == nil {
            account.storage.save( <- FLOAT.createEmptyCollection(), to: FLOAT.FLOATCollectionStoragePath)
            let cap = account.capabilities.storage.issue<&FLOAT.Collection>(FLOAT.FLOATCollectionStoragePath)
            account.capabilities.publish(cap, at: FLOAT.FLOATCollectionPublicPath)
        }

        let cole= account.storage.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)
        if cole == nil {
            account.storage.save( <- FLOAT.createEmptyFLOATEventCollection(), to: FLOAT.FLOATEventsStoragePath)
            let cap = account.capabilities.storage.issue<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsStoragePath)
            account.capabilities.publish(cap, at: FLOAT.FLOATEventsPublicPath)
        }

        /*
        // SETUP SHARED MINTING
        if acct.borrow<&GrantedAccountAccess.Info>(from: GrantedAccountAccess.InfoStoragePath) == nil {
            acct.save(<- GrantedAccountAccess.createInfo(), to: GrantedAccountAccess.InfoStoragePath)
            acct.link<&GrantedAccountAccess.Info{GrantedAccountAccess.InfoPublic}>
            (GrantedAccountAccess.InfoPublicPath, target: GrantedAccountAccess.InfoStoragePath)
        }
        */

        if forHost != account.address {
            let FLOATEvents = account.storage.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)
            ?? panic("Could not borrow the FLOATEvents from the signer.")
            self.FLOATEvents = FLOATEvents.borrowSharedRef(fromHost: forHost)
        } else {
            self.FLOATEvents = account.storage.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)
            ?? panic("Could not borrow the FLOATEvents from the signer.")
        }
    }

    execute {
        var Timelock: FLOATVerifiers.Timelock? = nil
        var Secret: FLOATVerifiers.Secret? = nil
        var Limited: FLOATVerifiers.Limited? = nil
        var MultipleSecret: FLOATVerifiers.MultipleSecret? = nil
        var verifiers: [{FLOAT.IVerifier}] = []
        if timelock {
            Timelock = FLOATVerifiers.Timelock(_dateStart: dateStart, _timePeriod: timePeriod)
            verifiers.append(Timelock!)
        }
        if secret {
            if secrets.length == 1 {
                Secret = FLOATVerifiers.Secret(_secretPhrase: secrets[0])
                verifiers.append(Secret!)
            } else {
                MultipleSecret = FLOATVerifiers.MultipleSecret(_secrets: secrets)
                verifiers.append(MultipleSecret!)
            }
        }
        if limited {
            Limited = FLOATVerifiers.Limited(_capacity: capacity)
            verifiers.append(Limited!)
        }
        let extraMetadata: {String: AnyStruct} = {}
        if flowTokenPurchase {
            let tokenInfo = FLOAT.TokenInfo(_path: /public/flowTokenReceiver, _price: flowTokenCost)
            extraMetadata["prices"] = {"A.2d4c3caffbeab845.FlowToken.Vault": tokenInfo}
        }
        self.FLOATEvents.createEvent(claimable: claimable, description: description, image: image, name: name, transferrable: transferrable, url: url, verifiers: verifiers, extraMetadata, initialGroups: initialGroups)
        log("Started a new event for host.")
    }
}  
