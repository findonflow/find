import "FUSD"
import "FungibleToken"
import "FIND"

transaction(name: String, amount: UFix64) {

    let vaultRef : auth (FungibleToken.Withdraw) &FUSD.Vault?
    let bidRef : &FIND.BidCollection?

    prepare(account: auth(BorrowValue) &Account) {

        self.vaultRef = account.storage.borrow< auth (FungibleToken.Withdraw) &FUSD.Vault>(from: /storage/fusdVault)
        self.bidRef = account.storage.borrow<&FIND.BidCollection>(from: FIND.BidStoragePath)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!" 
        self.bidRef != nil : "Could not borrow reference to the bid collection!" 
    }

    execute {
        let vault <- self.vaultRef!.withdraw(amount: amount) as! @FUSD.Vault
        self.bidRef!.bid(name: name, vault: <- vault)
    }
}
