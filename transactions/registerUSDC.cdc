import FiatToken from "../contracts/standard/FiatToken.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    let vaultRef : &FiatToken.Vault?
    let leases : &FIND.LeaseCollection?
    let price : UFix64

    prepare(account: AuthAccount) {

        self.price=FIND.calculateCost(name)
        log("The cost for registering this name is ".concat(self.price.toString()))
        self.vaultRef = account.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
        self.leases=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
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
