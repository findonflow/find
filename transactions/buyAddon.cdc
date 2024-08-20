import FIND from "../contracts/FIND.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"


transaction(name: String, addon:String, maxAmount:UFix64) {

    let leases : &FIND.LeaseCollection?
    let vaultRef : &FlowToken.Vault? 
    let cost:UFix64

    prepare(account: AuthAccount) {

        self.leases= account.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        self.vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        self.cost = FIND.calculateAddonCostInFlow(addon)

    }

    pre{
        self.leases != nil : "Could not borrow reference to the leases collection"
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.cost < maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
        self.vaultRef!.balance > self.cost : "Balance of vault is not high enough ".concat(self.vaultRef!.balance.toString().concat(" total balance is ").concat(self.vaultRef!.balance.toString()))
    }

    execute {
        let vault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
    }
}

