import FindMarket from "../contracts/FindMarket.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
//import FiatToken from "../contracts/standard/FiatToken.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

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



        /*
        //USDC
        let usdcCap = acct.getCapability<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if !usdcCap.check() {
            acct.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
            acct.link<&{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
            acct.link<&{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
            acct.link<&{FungibleToken.Vault}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
        }
        */


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
        /*
        if !types.contains(usdcCap.borrow()!.getType()) {
            switchboard.addNewVault(capability: usdcCap)
        }
        */
        if !types.contains(fusdReceiver!.borrow()!.getType()) {
            switchboard.addNewVault(capability: fusdReceiver!)
        }
        let flowTokenCap = account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)!
        if !types.contains(flowTokenCap.borrow()!.getType()) {
            switchboard.addNewVault(capability: flowTokenCap)
        }

    }
}

