import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, maxAmount: UFix64) {

    let vaultRef : &FlowToken.Vault? 
    let finLeases : &FIND.LeaseCollection? 
    let cost:UFix64

    prepare(acct: AuthAccount) {
        self.vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        self.finLeases= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        self.cost = FIND.calculateCostInFlow(name)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.finLeases != nil : "Could not borrow reference to find lease collection"
        self.cost < maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
        self.vaultRef!.balance > self.cost : "Balance of vault is not high enough ".concat(self.vaultRef!.balance.toString().concat(" total balance is ").concat(self.vaultRef!.balance.toString()))
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        let finToken= self.finLeases!.borrow(name)
        finToken.extendLease(<- payVault)
    }
}
