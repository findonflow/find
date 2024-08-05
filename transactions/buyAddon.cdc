import "FIND"
import "FlowToken"
import "FungibleToken"


transaction(name: String, addon:String, maxAmount:UFix64) {

    let leases : &FIND.LeaseCollection?
    let vaultRef : auth (FungibleToken.Withdraw) &FlowToken.Vault? 
    let cost: UFix64

    prepare(account: auth (BorrowValue, FungibleToken.Withdraw) &Account) {

        self.leases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        self.vaultRef = account.storage.borrow<auth (FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
        self.cost=FIND.calculateAddonCostInFlow(addon)
    }

    pre{
        self.leases != nil : "Could not borrow reference to the leases collection"
        self.vaultRef != nil : "Could not borrow reference to the flow token vault!"
        self.cost <= maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
        self.vaultRef!.balance > self.cost : "Balance of vault is not high enough ".concat(self.vaultRef!.balance.toString().concat(" total balance is ").concat(self.vaultRef!.balance.toString()))
    }

    execute {
        let vault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
    }
}

