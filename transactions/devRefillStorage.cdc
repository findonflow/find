import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FlowStorageFees from "../contracts/standard/FlowStorageFees.cdc"

transaction() {
    prepare(acct: auth(BorrowValue)  AuthAccountAccount) {

        let sender <- acct.load<@FlowToken.Vault>(from: /storage/unusedFlow)
            ?? panic("Cannot load FlowToken vault from temp flow storage")

        let vault <- sender

        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from authAcct storage")

        vaultRef.deposit(from: <- vault)
    }
}
