import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

transaction(receiver: Address, amount:UFix64) {
    prepare(acct: AuthAccount) {
        let receiver = getAccount(receiver).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver).borrow() ?? panic("Cannot borrow FlowToken receiver")

        let sender = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from authAcct storage")

        receiver.deposit(from: <- sender.withdraw(amount:amount))
    }
}
