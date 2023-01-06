import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FlowStorageFees from "../contracts/standard/FlowStorageFees.cdc"

transaction() {
    prepare(acct: AuthAccount) {

        let sender = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FlowToken vault from authAcct storage")

        let storageUsed = acct.storageUsed 
        let storageCapacity = acct.storageCapacity 
        let extraFlowBalance = FlowStorageFees.storageCapacityToFlow(FlowStorageFees.convertUInt64StorageBytesToUFix64Megabytes(storageCapacity - storageUsed) - 0.2) // 0.1 Mb extra here for fillup

        let vault <- sender.withdraw(amount: extraFlowBalance)

        acct.save(<- vault, to: /storage/unusedFlow)

    }
}
