import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    let vaultRef : &FlowToken.Vault?
    let leases : &FIND.LeaseCollection?

    prepare(account: AuthAccount) {
        self.vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        self.leases=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
        FIND.validateCostInFlow(name: name, flow: amount)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.leases != nil : "Could not borrow reference to find lease collection"
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: amount) as! @FlowToken.Vault
        self.leases!.register(name: name, vault: <- payVault)
    }
}
