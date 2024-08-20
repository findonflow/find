import "FlowToken"
import "FungibleToken"
import "FIND"

transaction(name: String, maxAmount: UFix64) {

    let cost : UFix64
    let vaultRef : auth (FungibleToken.Withdraw) &FlowToken.Vault? 
    let finLeases : auth(FIND.LeaseOwner) &FIND.LeaseCollection? 

    prepare(acct: auth(BorrowValue) &Account) {
        self.cost=FIND.calculateCostInFlow(name)
        self.vaultRef = acct.storage.borrow<auth (FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
        self.finLeases= acct.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
    }


    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.finLeases != nil : "Could not borrow reference to find lease collection"
        self.cost <= maxAmount : "You have not sent in enough max flow, the cost is ".concat(self.cost.toString())
        self.vaultRef!.balance > self.cost : "Balance of vault is not high enough ".concat(self.vaultRef!.balance.toString().concat(" total balance is ").concat(self.vaultRef!.balance.toString()))
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.cost) as! @FlowToken.Vault
        let finToken= self.finLeases!.borrow(name)
        finToken.extendLease(<- payVault)
    }
}
