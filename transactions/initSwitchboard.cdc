import "FungibleToken"
import "FlowToken"
import "TokenForwarding"
import "FungibleTokenSwitchboard"
import "DapperUtilityCoin"
import "FlowUtilityToken"

transaction(dapperAddress: Address) {
    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {

        let dapper = getAccount(dapperAddress)

        //Dapper utility token
        var DUCReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        if !DUCReceiver.check(){
            let dapperDUCReceiver = dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
            let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapperDUCReceiver)
            account.storage.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
            DUCReceiver = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/dapperUtilityCoinReceiver)
            account.capabilities.publish(DUCReceiver, at: /public/dapperUtilityCoinReceiver)
        }

        //FlowUtility token
        var FUTReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        if !FUTReceiver.check(){
            let dapperFUTReceiver = dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
            account.storage.save(<-futForwarder, to: /storage/flowUtilityTokenVault)
            FUTReceiver = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/flowUtilityTokenVault)
            account.capabilities.publish(FUTReceiver, at: /public/flowUtilityTokenReceiver)
        }

        let switchboardRef = account.storage.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)
        if switchboardRef == nil {
            let sb <- FungibleTokenSwitchboard.createSwitchboard()
            account.storage.save(<- sb, to: FungibleTokenSwitchboard.StoragePath)

            let cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.StoragePath)
            account.capabilities.publish(cap, at: FungibleTokenSwitchboard.ReceiverPublicPath)

            let capb = account.capabilities.storage.issue<&{FungibleTokenSwitchboard.SwitchboardPublic,FungibleToken.Receiver}>(FungibleTokenSwitchboard.StoragePath)
            account.capabilities.publish(capb, at: FungibleTokenSwitchboard.PublicPath)
        }

        let switchboard = account.storage.borrow<auth(FungibleTokenSwitchboard.Owner) &FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)!

        if !switchboard.isSupportedVaultType(type:Type<@DapperUtilityCoin.Vault>()) {
            switchboard.addNewVaultWrapper(capability: DUCReceiver, type: Type<@DapperUtilityCoin.Vault>())
        }
        if !switchboard.isSupportedVaultType(type: Type<@FlowUtilityToken.Vault>()) {
            switchboard.addNewVaultWrapper(capability: FUTReceiver, type: Type<@FlowUtilityToken.Vault>())
        }
        let flowTokenCap = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        if !switchboard.isSupportedVaultType(type: flowTokenCap.borrow()!.getType()) {
            switchboard.addNewVault(capability: flowTokenCap)
        }


    }
}
