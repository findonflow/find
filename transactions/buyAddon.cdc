import "FUSD"
import "FIND"
import "FungibleToken"


transaction(name: String, addon:String, amount:UFix64) {

    let leases : &FIND.LeaseCollection?
    let vaultRef : auth (FungibleToken.Withdrawable) &FUSD.Vault? 

    prepare(account: auth (BorrowValue, FungibleToken.Withdrawable) &Account) {

        self.leases= account.storage.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
        self.vaultRef = account.storage.borrow<auth (FungibleToken.Withdrawable) &FUSD.Vault>(from: /storage/fusdVault)

    }

    pre{
        self.leases != nil : "Could not borrow reference to the leases collection"
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
    }

    execute {
        let vault <- self.vaultRef!.withdraw(amount: amount)
        //TODO: entitlements
        self.leases!.buyAddon(name: name, addon: addon, vault: <- vault)
    }
}

