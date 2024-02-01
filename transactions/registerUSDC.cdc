import FiatToken from "../contracts/standard/FiatToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    let vaultRef : auth(FungibleToken.Withdraw) &FiatToken.Vault?
    let leases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?
    let price : UFix64

    prepare(account: auth(BorrowValue) &Account) {

        self.price=FIND.calculateCost(name)
        log("The cost for registering this name is ".concat(self.price.toString()))
        self.vaultRef = account.storage.borrow<auth(FungibleToken.Withdraw) &FiatToken.Vault>(from: FiatToken.VaultStoragePath)
        self.leases=account.storage.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
    }

    pre{
        self.vaultRef != nil : "Could not borrow reference to the USDC Vault!"
        self.leases != nil : "Could not borrow reference to find lease collection"
        self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
    }

    execute{
        let payVault <- self.vaultRef!.withdraw(amount: self.price) as! @FiatToken.Vault
        self.leases!.registerUSDC(name: name, vault: <- payVault)
    }
}
