import FLOAT from "../contracts/standard/FLOAT.cdc"
import FLOATVerifiers from "../contracts/standard/FLOATVerifiers.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import GrantedAccountAccess from "../contracts/standard/GrantedAccountAccess.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(eventId: UInt64, host: Address) {

    let FLOATEvent: &FLOAT.FLOATEvent
    let Collection: &FLOAT.Collection
    let FlowTokenVault: auth (FungibleToken.Withdraw) &FlowToken.Vault

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





        let FLOATEvents = getAccount(host).capabilities.borrow<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPublicPath) ?? panic("Could not borrow the public FLOATEvents from the host.")

        self.FLOATEvent = FLOATEvents.borrowPublicEventRef(eventId: eventId) ?? panic("This event does not exist.")

        self.Collection = account.storage.borrow<&FLOAT.Collection>(from: FLOAT.FLOATCollectionStoragePath) ?? panic("Could not get the Collection from the signer.")

        self.FlowTokenVault = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow the FlowToken.Vault from the signer.")
    }

    execute {
        let params: {String: AnyStruct} = {}
        let secret = nil
        // If the FLOAT has a secret phrase on it
        if let unwrappedSecret = secret {
            params["secretPhrase"] = unwrappedSecret
        }

        // If the FLOAT costs something
        if let prices = self.FLOATEvent.getPrices() {
            log(prices)
            let payment <- self.FlowTokenVault.withdraw(amount: prices[self.FlowTokenVault.getType().identifier]!.price)
            self.FLOATEvent.purchase(recipient: self.Collection, params: params, payment: <- payment)
            log("Purchased the FLOAT.")
        }
        // If the FLOAT is free 
        else {
            self.FLOATEvent.claim(recipient: self.Collection, params: params)
            log("Claimed the FLOAT.")
        }
    }
}      
