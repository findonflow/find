import "FIND"
import "FungibleToken"
import "FUSD"

transaction(name: String, amount: UFix64) {

    let vaultRef : auth (FungibleToken.Withdraw) &FUSD.Vault?
    let bids : &FIND.BidCollection?

    prepare(account: auth(BorrowValue) &Account) {
        self.vaultRef = account.storage.borrow< auth (FungibleToken.Withdraw) &FUSD.Vault>(from: /storage/fusdVault)
        self.bids = account.storage.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.bids != nil : "Could not borrow reference to bid collection"
    }

    execute{
        let vault <- self.vaultRef!.withdraw(amount: amount)
        self.bids!.increaseBid(name: name, vault: <- vault)
    }
}
