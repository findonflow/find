import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, maxAmount: UFix64) {

    let vaultRef : &FlowToken.Vault?
    let leases : &FIND.LeaseCollection?
    let cost : UFix64

    prepare(account: AuthAccount) {
        self.vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        self.leases=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)

        self.cost = FIND.calculateCostInFlow(name)
    }

    pre{
        self.cost < maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.leases != nil : "Could not borrow reference to find lease collection"
        self.vaultRef!.balance > self.cost : "Balance of vault is not high enough ".concat(self.vaultRef!.balance.toString().concat(" total balance is ").concat(self.vaultRef!.balance.toString()))
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        self.leases!.register(name: name, vault: <- payVault)
    }
}
