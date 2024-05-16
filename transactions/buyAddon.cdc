import "FUSD"
import "FIND"
import "FungibleToken"


transaction(name: String, addon:String, amount:UFix64) {

    let leases : &FIND.LeaseCollection?
    let vaultRef : auth (FungibleToken.Withdraw) &FUSD.Vault? 

    prepare(account: auth (BorrowValue, FungibleToken.Withdraw) &Account) {

        self.leases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        self.vaultRef = account.storage.borrow<auth (FungibleToken.Withdraw) &FUSD.Vault>(from: /storage/fusdVault)

    }

    pre{
        self.leases != nil : "Could not borrow reference to the leases collection"
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
    }

    execute {
        let vault <- self.vaultRef!.withdraw(amount: amount) as! @FUSD.Vault
        self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
    }
}

