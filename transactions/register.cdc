import "FlowToken"
import "FIND"
import "FungibleToken"

transaction(name: String, maxAmount: UFix64) {

    let vaultRef : auth(FungibleToken.Withdraw) &FlowToken.Vault?
    let leases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?
    let cost : UFix64

    prepare(account: auth(BorrowValue) &Account) {

        self.vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
        self.leases=account.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from: FIND.LeaseStoragePath)

        self.cost = FIND.calculateCostInFlow(name)

    }


    pre{
        self.cost <= maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.leases != nil : "Could not borrow reference to find lease collection"
        self.vaultRef!.balance > self.cost : "Balance of vault is not high enough ".concat(self.cost.toString()).concat(" total balance is ").concat(self.vaultRef!.balance.toString())
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        self.leases!.register(name: name, vault: <- payVault)
    }
}
