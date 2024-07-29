import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    let vaultRef : &FlowToken.Vault?
    let leases : &FIND.LeaseCollection?
    let price : UFix64

    prepare(account: AuthAccount) {

        self.price=FIND.calculateCost(name) * 0.42
        log("The cost for registering this name is ".concat(self.price.toString()))
        self.vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
        self.leases=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.leases != nil : "Could not borrow reference to find lease collection"
        self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.price) as! @FlowToken.Vault
        self.leases!.register(name: name, vault: <- payVault)
    }
}
