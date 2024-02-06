import "FindMarket"
import "FungibleToken"
import "FlowToken"
import "FUSD"
import "FiatToken"
import "TokenForwarding"
import "FungibleTokenSwitchboard"
import "DapperUtilityCoin"
import "FlowUtilityToken"

//Transaction that is signed by find to create a find market tenant for find
transaction(dapperAddress: Address) {
    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability) &Account) {

        //in finds case the
        account.storage.save(<- FindMarket.createTenantClient(), to:FindMarket.TenantClientStoragePath)

        let capb = account.capabilities.storage.issue<&{FindMarket.TenantClientPublic}>(FindMarket.TenantClientStoragePath)
        account.capabilities.publish(capb, at: FindMarket.TenantClientPublicPath)

        // Get a Receiver reference for the Dapper account that will be the recipient of the forwarded DUC and FUT
        let dapper = getAccount(dapperAddress)

        //FUSD
        var fusdReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if fusdReceiver == nil {
            let fusd <- FUSD.createEmptyVault()

            account.storage.save(<- fusd, to: /storage/fusdVault)
            var cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/fusdVault)
            account.capabilities.publish(cap, at: /public/fusdReceiver)
            let capb = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/fusdVault)
            account.capabilities.publish(capb, at: /public/fusdBalance)
            fusdReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        }


        var usdcCap = account.capabilities.get<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if usdcCap == nil {
            account.storage.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
            let cap = account.capabilities.storage.issue<&FiatToken.Vault>(FiatToken.VaultStoragePath)
            account.capabilities.publish(cap, at: FiatToken.VaultUUIDPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultReceiverPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultBalancePubPath)
            usdcCap = account.capabilities.get<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        }



        //Dapper utility token
        let dapperDUCReceiver = dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)!
        let DUCReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        if DUCReceiver == nil{
            let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapperDUCReceiver)
            account.storage.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
            let cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/dapperUtilityCoinReceiver)
            account.capabilities.publish(cap, at: /public/dapperUtilityCoinReceiver)
        }

        //FlowUtility token
        let dapperFUTReceiver = dapper.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!
        let FUTReceiver = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        if FUTReceiver ==nil{
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
            account.storage.save(<-futForwarder, to: /storage/flowUtilityTokenVault)
            let cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/flowUtilityTokenVault)
            account.capabilities.publish(cap, at: /public/flowUtilityTokenReceiver)
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

        let switchboard = account.storage.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)!
        let types = switchboard.getVaultTypes()
        if !types.contains(Type<@DapperUtilityCoin.Vault>()) {
            switchboard.addNewVaultWrapper(capability: dapperDUCReceiver, type: Type<@DapperUtilityCoin.Vault>())
        }
        if !types.contains(Type<@FlowUtilityToken.Vault>()) {
            switchboard.addNewVaultWrapper(capability: dapperFUTReceiver, type: Type<@FlowUtilityToken.Vault>())
        }
        if !types.contains(usdcCap!.borrow()!.getType()) {
            switchboard.addNewVault(capability: usdcCap!)
        }
        if !types.contains(fusdReceiver!.borrow()!.getType()) {
            switchboard.addNewVault(capability: fusdReceiver!)
        }
        let flowTokenCap = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        if !types.contains(flowTokenCap.borrow()!.getType()) {
            switchboard.addNewVault(capability: flowTokenCap)
        }

    }
}

