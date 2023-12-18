import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"

transaction(dapperAddress: Address) {
    prepare(acct: auth(BorrowValue) &Account) {

        let dapper = getAccount(dapperAddress)

        //FUSD
        let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if !fusdReceiver.check() {
            let fusd <- FUSD.createEmptyVault()
            acct.save(<- fusd, to: /storage/fusdVault)
            acct.link<&{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
            acct.link<&{FungibleToken.Vault}>( /public/fusdBalance, target: /storage/fusdVault)
        }

        //USDC
        let usdcCap = acct.getCapability<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if !usdcCap.check() {
            acct.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
            acct.link<&{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
            acct.link<&{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
            acct.link<&{FungibleToken.Vault}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
        }


        //Dapper utility token
        let dapperDUCReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        let DUCReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
        if !DUCReceiver.check(){
            let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapperDUCReceiver)
            acct.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
            acct.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver, target: /storage/dapperUtilityCoinReceiver)
        }

        //FlowUtility token
        let dapperFUTReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        let FUTReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        if !FUTReceiver.check(){
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
            acct.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)
            acct.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver, target: /storage/flowUtilityTokenReceiver)
        }

        let switchboardRef = acct.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)
        if switchboardRef == nil{
            let sb <- FungibleTokenSwitchboard.createSwitchboard()
            acct.save(<- sb, to: FungibleTokenSwitchboard.StoragePath)
            acct.link<&{FungibleToken.Receiver}>( FungibleTokenSwitchboard.ReceiverPublicPath, target: FungibleTokenSwitchboard.StoragePath)
            acct.link<&{FungibleTokenSwitchboard.SwitchboardPublic, FungibleToken.Receiver}>(
                FungibleTokenSwitchboard.PublicPath,
                target: FungibleTokenSwitchboard.StoragePath
            )
        }
        let switchboard = acct.borrow<&FungibleTokenSwitchboard.Switchboard>(from: FungibleTokenSwitchboard.StoragePath)!
        let types = switchboard.getVaultTypes()
        if !types.contains(Type<@DapperUtilityCoin.Vault>()) {
            switchboard.addNewVaultWrapper(capability: dapperDUCReceiver, type: Type<@DapperUtilityCoin.Vault>())
        }
        if !types.contains(Type<@FlowUtilityToken.Vault>()) {
            switchboard.addNewVaultWrapper(capability: dapperFUTReceiver, type: Type<@FlowUtilityToken.Vault>())
        }
        if !types.contains(usdcCap.borrow()!.getType()) {
            switchboard.addNewVault(capability: usdcCap)
        }
        if !types.contains(fusdReceiver.borrow()!.getType()) {
            switchboard.addNewVault(capability: fusdReceiver)
        }
        let flowTokenCap = acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        if !types.contains(flowTokenCap.borrow()!.getType()) {
            switchboard.addNewVault(capability: flowTokenCap)
        }

    }
}
