import FUSD from "../contracts/standard/FUSD.cdc"
import FiNS from "../contracts/FiNS.cdc"

transaction(tag: String, amount: UFix64) {

    prepare(account: AuthAccount) {
        let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the owner's Vault!")

        log("Sending ".concat(amount.toString()).concat( " to profile with tag ").concat(tag))
        FiNS.deposit(to: tag, from: <- vaultRef.withdraw(amount: amount))
    }

}
 
