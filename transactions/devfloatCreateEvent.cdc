import FLOAT from "../contracts/standard/FLOAT.cdc"
import FLOATVerifiers from "../contracts/standard/FLOATVerifiers.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import GrantedAccountAccess from "../contracts/standard/GrantedAccountAccess.cdc"

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

  prepare(acct: AuthAccount) {
    // SETUP COLLECTION
    if acct.borrow<&FLOAT.Collection>(from: FLOAT.FLOATCollectionStoragePath) == nil {
        acct.save(<- FLOAT.createEmptyCollection(), to: FLOAT.FLOATCollectionStoragePath)
        acct.link<&FLOAT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection, FLOAT.CollectionPublic}>
                (FLOAT.FLOATCollectionPublicPath, target: FLOAT.FLOATCollectionStoragePath)
    }

    // SETUP FLOATEVENTS
    if acct.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath) == nil {
      acct.save(<- FLOAT.createEmptyFLOATEventCollection(), to: FLOAT.FLOATEventsStoragePath)
      acct.link<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic, ViewResolver.ResolverCollection}>
                (FLOAT.FLOATEventsPublicPath, target: FLOAT.FLOATEventsStoragePath)
    }

    // SETUP SHARED MINTING
    if acct.borrow<&GrantedAccountAccess.Info>(from: GrantedAccountAccess.InfoStoragePath) == nil {
        acct.save(<- GrantedAccountAccess.createInfo(), to: GrantedAccountAccess.InfoStoragePath)
        acct.link<&GrantedAccountAccess.Info{GrantedAccountAccess.InfoPublic}>
                (GrantedAccountAccess.InfoPublicPath, target: GrantedAccountAccess.InfoStoragePath)
    }
    
    if forHost != acct.address {
      let FLOATEvents = acct.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)
                        ?? panic("Could not borrow the FLOATEvents from the signer.")
      self.FLOATEvents = FLOATEvents.borrowSharedRef(fromHost: forHost)
    } else {
      self.FLOATEvents = acct.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)
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
