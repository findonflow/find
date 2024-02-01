import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FlowStorageFees from "../contracts/standard/FlowStorageFees.cdc"

transaction() {
    prepare(acct: auth(BorrowValue, SaveValue, FungibleToken.Withdraw) &Account) {

        let sender = acct.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
        ?? panic("Cannot borrow FlowToken vault from authAcct storage")

        let storageUsed = acct.storage.used
        let storageCapacity = acct.storage.capacity
        let extraFlowBalance = FlowStorageFees.storageCapacityToFlow(FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(storageCapacity - storageUsed) - 0.1) // 0.1 Mb extra here for fillup

        let vault <- sender.withdraw(amount: extraFlowBalance)

        acct.storage.save(<- vault, to: /storage/unusedFlow)

    }
}
