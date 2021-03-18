
//emulator
import NonFungibleToken, Content, FIN from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FlowToken from 0x0ae53cb6e3f42a79

transaction(tag: String, amount: UFix64) {

    prepare(account: AuthAccount) {
        let vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow reference to the owner's Vault!")

        log("Sending ".concat(amount.toString()).concat( " to profile with tag ").concat(tag))
        FIN.deposit(to: tag, from: <- vaultRef.withdraw(amount: amount))
    }

}
 