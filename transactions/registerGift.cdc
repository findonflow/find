import FlowToken from "../contracts/standard/FlowToken.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, maxAmount: UFix64, recipient: String) {

    let vaultRef : &FlowToken.Vault? 
    let receiverLease : Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>
    let receiverProfile : Capability<&{Profile.Public}>
    let leases : &FIND.LeaseCollection?
    let cost : UFix64

    prepare(acct: AuthAccount) {

        let resolveAddress = FIND.resolve(recipient)
        if resolveAddress == nil {panic("The input pass in is not a valid name or address. Input : ".concat(recipient))}
        let address = resolveAddress!


        self.vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)

        self.leases=acct.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)

        let receiver = getAccount(address)
        self.receiverLease = receiver.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
        self.receiverProfile = receiver.getCapability<&{Profile.Public}>(Profile.publicPath)

        self.cost = FIND.calculateCostInFlow(name)

    }

    pre{
        self.vaultRef != nil : "Cannot borrow reference to fusd Vault!"
        self.receiverLease.check() : "Lease capability is invalid"
        self.receiverProfile.check() : "Profile capability is invalid"
        self.leases != nil : "Cannot borrow refernce to find lease collection"
        self.cost < maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        self.leases!.register(name: name, vault: <- payVault)
        self.leases!.move(name: name, profile: self.receiverProfile, to: self.receiverLease)
    }
}
