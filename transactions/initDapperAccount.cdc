import "FungibleToken"
import "DapperUtilityCoin"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc" 
import "TokenForwarding"

transaction(dapperAddress: Address) {
    prepare(account: auth(BorrowValue, SaveValue, Capabilities) &Account) {

        let dapper=getAccount(dapperAddress)
        //this is only for emulator
        let ducReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        if !ducReceiver.check() {
            // Create a new Forwarder resource for DUC and store it in the new account's storage
            let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
            account.storage.save(<-ducForwarder, to: /storage/dapperUtilityCoinVault)
            let receiverCap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/dapperUtilityCoinVault)
            account.capabilities.publish(receiverCap, at: /public/dapperUtilityCoinReceiver)

            let vaultCap = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/dapperUtilityCoinVault)
            account.capabilities.publish(vaultCap, at: /public/dapperUtilityCoinVault)
        }

        //this is only for emulator
        let futReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        if !futReceiver.check() {
            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver))
            account.storage.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)
            let receiverCap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/flowUtilityTokenReceiver)
            account.capabilities.publish(receiverCap, at: /public/flowUtilityTokenReceiver)

            let vaultCap = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/flowUtilityTokenReceiver)
            account.capabilities.publish(vaultCap, at: /public/flowUtilityTokenVault)
        }
    }
}
