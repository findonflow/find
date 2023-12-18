import "FUSD" 
import "FIND"
import "FungibleToken"

transaction(name: String, amount: UFix64) {

    let vaultRef : auth(FungibleToken.Withdrawable) &FUSD.Vault?
    let leases : &FIND.LeaseCollection?
    let price : UFix64

    prepare(account: auth(BorrowValue, FungibleToken.Withdrawable) &Account) {

        self.price=FIND.calculateCost(name)
        log("The cost for registering this name is ".concat(self.price.toString()))
        self.vaultRef = account.storage.borrow<auth(FungibleToken.Withdrawable) &FUSD.Vault>(from: /storage/fusdVault)
        self.leases=account.storage.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.leases != nil : "Could not borrow reference to find lease collection"
        self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.price)

        //TODO: entitlements
        self.leases!.register(name: name, vault: <- payVault)
    }
}
