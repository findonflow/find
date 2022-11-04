
      import FLOAT from "../contracts/standard/FLOAT.cdc"
      import FLOATVerifiers from "../contracts/standard/FLOATVerifiers.cdc"
      import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
      import MetadataViews from "../contracts/standard/MetadataViews.cdc"
      import GrantedAccountAccess from "../contracts/standard/GrantedAccountAccess.cdc"
      import FlowToken from "../contracts/standard/FlowToken.cdc"

      transaction(eventId: UInt64, host: Address) {
 
        let FLOATEvent: &FLOAT.FLOATEvent{FLOAT.FLOATEventPublic}
        let Collection: &FLOAT.Collection
        let FlowTokenVault: &FlowToken.Vault
      
        prepare(acct: AuthAccount) {
          // SETUP COLLECTION
          if acct.borrow<&FLOAT.Collection>(from: FLOAT.FLOATCollectionStoragePath) == nil {
              acct.save(<- FLOAT.createEmptyCollection(), to: FLOAT.FLOATCollectionStoragePath)
              acct.link<&FLOAT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, FLOAT.CollectionPublic}>
                      (FLOAT.FLOATCollectionPublicPath, target: FLOAT.FLOATCollectionStoragePath)
          }
      
          // SETUP FLOATEVENTS
          if acct.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath) == nil {
            acct.save(<- FLOAT.createEmptyFLOATEventCollection(), to: FLOAT.FLOATEventsStoragePath)
            acct.link<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic, MetadataViews.ResolverCollection}>
                      (FLOAT.FLOATEventsPublicPath, target: FLOAT.FLOATEventsStoragePath)
          }
      
          // SETUP SHARED MINTING
          if acct.borrow<&GrantedAccountAccess.Info>(from: GrantedAccountAccess.InfoStoragePath) == nil {
              acct.save(<- GrantedAccountAccess.createInfo(), to: GrantedAccountAccess.InfoStoragePath)
              acct.link<&GrantedAccountAccess.Info{GrantedAccountAccess.InfoPublic}>
                      (GrantedAccountAccess.InfoPublicPath, target: GrantedAccountAccess.InfoStoragePath)
          }
      
          let FLOATEvents = getAccount(host).getCapability(FLOAT.FLOATEventsPublicPath)
                              .borrow<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>()
                              ?? panic("Could not borrow the public FLOATEvents from the host.")
          self.FLOATEvent = FLOATEvents.borrowPublicEventRef(eventId: eventId) ?? panic("This event does not exist.")
      
          self.Collection = acct.borrow<&FLOAT.Collection>(from: FLOAT.FLOATCollectionStoragePath)
                              ?? panic("Could not get the Collection from the signer.")
          
          self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
                                  ?? panic("Could not borrow the FlowToken.Vault from the signer.")
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