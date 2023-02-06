import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc"
import FungibleTokenSwitchboard from "../contracts/standard/FungibleTokenSwitchboard.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

/** 
 This is a transaction to set up an merchant account

 It has to be a blocto account since dapper will not allow us to run this account on a merchan account
 
 The only input parameter to this is your merchant account at dapper
**/

transaction(dapperAccountAddress: Address) {

	prepare(acct: AuthAccount) {
		// Get a Receiver reference for the Dapper account that will be the recipient of the forwarded DUC and FUT
		let dapper = getAccount(dapperAccountAddress)

		//FUSD
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		//USDC
		let usdcCap = acct.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
		if !usdcCap.check() {
				acct.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
        acct.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
        acct.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
				acct.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target:FiatToken.VaultStoragePath)
		}


		//Dapper utility token
	  let dapperDUCReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !dapperDUCReceiver.check(){
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapperDUCReceiver)
			acct.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
			acct.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver, target: /storage/dapperUtilityCoinReceiver)
		}

		//FlowUtility token
	  let dapperFUTReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		if !dapperFUTReceiver.check(){
			let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
			acct.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)
			acct.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver, target: /storage/flowUtilityTokenReceiver)
		}

		let switchboard <- FungibleTokenSwitchboard.createSwitchboard()
		switchboard.addNewVaultWrapper(capability: dapperDUCReceiver, type: Type<@DapperUtilityCoin.Vault>())
		switchboard.addNewVaultWrapper(capability: dapperFUTReceiver, type: Type<@FlowUtilityToken.Vault>())
		switchboard.addNewVault(capability: usdcCap)
		switchboard.addNewVault(capability: fusdReceiver)
		switchboard.addNewVault(capability: acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver))

		acct.save(<- switchboard, to: FungibleTokenSwitchboard.StoragePath)
		acct.link<&FungibleTokenSwitchboard.Switchboard{FungibleToken.Receiver}>( FungibleTokenSwitchboard.ReceiverPublicPath, target: FungibleTokenSwitchboard.StoragePath)
		acct.link<&FungibleTokenSwitchboard.Switchboard{FungibleTokenSwitchboard.SwitchboardPublic, FungibleToken.Receiver}>(
		    FungibleTokenSwitchboard.PublicPath,
		    target: FungibleTokenSwitchboard.StoragePath
		)
	}
}
