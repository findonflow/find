import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

    prepare(account: AuthAccount) {
        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")

        log("Sending ".concat(amount.toString()).concat( " to profile with name ").concat(name))
        FIND.deposit(to: name, from: <- vaultRef.withdraw(amount: amount))
    }

}
 
