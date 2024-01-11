import FUSD from "../contracts/standard/FUSD.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    let price : UFix64
    let vaultRef : auth (FungibleToken.Withdrawable) &FUSD.Vault? 
    let finLeases : &FIND.LeaseCollection? 

    prepare(acct: auth(BorrowValue) &Account) {
        self.price=FIND.calculateCost(name)
        self.vaultRef = acct.storage.borrow<auth (FungibleToken.Withdrawable) &FUSD.Vault>(from: /storage/fusdVault)
        self.finLeases= acct.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from:FIND.LeaseStoragePath)
    }

    pre{
        self.price == amount : "expected renew cost : ".concat(self.price.toString()).concat(" is not the same as calculated renew cost : ").concat(amount.toString())
        self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
        self.finLeases != nil : "Could not borrow reference to find lease collection"
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.price) 
        let finToken= self.finLeases!.borrow(name)
        finToken.extendLease(<- payVault)
    }
}
