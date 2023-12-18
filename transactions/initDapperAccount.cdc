import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc" 
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"

transaction(dapperAddress: Address) {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {

		let dapper=getAccount(dapperAddress)
		//this is only for emulator
		let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !ducReceiver.check() {
			// Create a new Forwarder resource for DUC and store it in the new account's storage
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinVault)
			// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
		}

		//this is only for emulator
		let futReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		if !futReceiver.check() {
			// Create a new Forwarder resource for FUT and store it in the new account's storage
			let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver))
			account.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)
			// Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver,target: /storage/flowUtilityTokenReceiver)
		}
	}
}
