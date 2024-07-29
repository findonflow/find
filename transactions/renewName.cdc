import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    let vaultRef : &FlowToken.Vault? 
    let finLeases : &FIND.LeaseCollection? 

    prepare(acct: AuthAccount) {
        self.vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        self.finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        FIND.validateCostInFlow(name: name, flow: amount)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.finLeases != nil : "Could not borrow reference to find lease collection"
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: amount) as! @FlowToken.Vault
        let finToken= self.finLeases!.borrow(name)
        finToken.extendLease(<- payVault)
    }
}
