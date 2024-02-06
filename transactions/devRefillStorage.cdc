import "FungibleToken"
import "FlowToken"
import "FlowStorageFees"

transaction() {
    prepare(acct: auth(BorrowValue) &Account) {

        let sender <- acct.load<@FlowToken.Vault>(from: /storage/unusedFlow)
            ?? panic("Cannot load FlowToken vault from temp flow storage")

        let vault <- sender

        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from authAcct storage")

        vaultRef.deposit(from: <- vault)
    }
}
