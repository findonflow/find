import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61
import TokenForwarding from 0xe544175ee0461c4b
import FungibleTokenSwitchboard from 0xf233dcee88fe0abe
import DapperUtilityCoin from 0xead892083b3e2c6c
import EVMVMBridgedToken_2aabea2058b5ac2d339b163c6ab6f2b6d53aabedVault  from 0x1e4aa0b87d10b141 //USDF
/*
*
* This Transasction set up a flow account to receive royalty from both flow and dapper transactions. 
*
* For DUC/FUT the flow is <this address> -> <your dapper address> -> <main daper wallet>. So all DUC/FUT end up back at where they belong
*/
transaction(dapperAddress: Address) {
    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {

        // Get a Receiver reference for the Dapper account that will be the recipient of the forwarded DUC and FUT
        let dapper = getAccount(dapperAddress)

        //lets set up the fungible token switchboard so that we can register tokens in it
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


        //Dapper utility token
        var ducReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        if !ducReceiver.check(){
            let dapperducReceiver = dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
            let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapperducReceiver)
            account.storage.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
            ducReceiver= account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/dapperUtilityCoinReceiver)
            account.capabilities.publish(ducReceiver, at: /public/dapperUtilityCoinReceiver)
        }
        if !switchboard.isSupportedVaultType(type:Type<@DapperUtilityCoin.Vault>()) {
            switchboard.addNewVaultWrapper(capability: ducReceiver, type: Type<@DapperUtilityCoin.Vault>())
        }


        //USDF
        let usdfStoragePath = /storage/EVMVMBridgedToken_2aabea2058b5ac2d339b163c6ab6f2b6d53aabedVault
        let usdfBalancePath = /public/EVMVMBridgedToken_2aabea2058b5ac2d339b163c6ab6f2b6d53aabedVault

        let usdfPublicPath = /public/EVMVMBridgedToken_2aabea2058b5ac2d339b163c6ab6f2b6d53aabedReceiver
        let usdfType=Type<@EVMVMBridgedToken_2aabea2058b5ac2d339b163c6ab6f2b6d53aabed.Vault>()
        var usdfReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(usdfPublicPath)

        if !usdfReceiver.check(){
            let vault <- EVMVMBridgedToken_2aabea2058b5ac2d339b163c6ab6f2b6d53aabed.createEmptyVault(vaultType:usdfType)
            account.storage.save(<-vault, to: usdfStoragePath)

            let usdfReceiverBalance= account.capabilities.storage.issue<&{FungibleToken.Balance}>(usdfStoragePath)
            account.capabilities.publish(usdfReceiverBalance, at: usdfBalancePath)

            usdfReceiver= account.capabilities.storage.issue<&{FungibleToken.Receiver}>(usdfStoragePath)
            account.capabilities.publish(usdfReceiver, at: usdfPublicPath)
        }

        if !switchboard.isSupportedVaultType(type:usdfType) {
            switchboard.addNewVaultWrapper(capability: usdfReceiver, type:usdfType)
        }

        //FLOW
        let flowTokenCap = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        if !switchboard.isSupportedVaultType(type: flowTokenCap.borrow()!.getType()) {
            switchboard.addNewVault(capability: flowTokenCap)
        }

    }
}

