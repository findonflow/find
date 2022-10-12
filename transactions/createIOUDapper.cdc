import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import IOweYou from "../contracts/IOweYou.cdc" 
import DapperIOweYou from "../contracts/DapperIOweYou.cdc" 
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc" 
import Profile from "../contracts/Profile.cdc" 
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc" 
import FlowUtilityToken from "../contracts/standard/FlowUtilityToken.cdc" 

transaction(name: String, amount: UFix64) {

	let walletReference : &FungibleToken.Vault
	let walletBalance : UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!

		let ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !ducReceiver.check() {
			// Create a new Forwarder resource for DUC and store it in the new account's storage
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinVault)
			// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinVault)
		}

		let futReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
		if !futReceiver.check() {
			// Create a new Forwarder resource for FUT and store it in the new account's storage
			let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-futForwarder, to: /storage/flowUtilityTokenVault)
			// Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver,target: /storage/flowUtilityTokenVault)
		}

		var updated = false

		if !profile.hasWallet("DUC") {
			let ducWallet=Profile.Wallet( name:"DUC", receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver), balance:dapper.getCapability<&{FungibleToken.Balance}>(/public/dapperUtilityCoinBalance), accept: Type<@DapperUtilityCoin.Vault>(), tags: ["duc", "dapper", "dapperUtilityCoin"])
			profile.addWallet(ducWallet)
			updated=true
		}
		if !profile.hasWallet("FUT") {
			let futWallet=Profile.Wallet( name:"FUT", receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver), balance:dapper.getCapability<&{FungibleToken.Balance}>(/public/flowUtilityTokenBalance), accept: Type<@FlowUtilityToken.Vault>(), tags: ["fut", "dapper", "flowUtilityToken"])
			profile.addWallet(futWallet)
			updated=true
		}

		if updated {
			profile.emitUpdatedEvent()
		}

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		if account.borrow<&DapperIOweYou.Collection>(from: DapperIOweYou.CollectionStoragePath) == nil {
			account.save<@DapperIOweYou.Collection>( <- DapperIOweYou.createEmptyCollection(receiverCap) , to: DapperIOweYou.CollectionStoragePath)
			account.link<&DapperIOweYou.Collection{IOweYou.CollectionPublic}>(DapperIOweYou.CollectionPublicPath, target: DapperIOweYou.CollectionStoragePath)
		}
		let collectionRef = account.borrow<&DapperIOweYou.Collection>(from: DapperIOweYou.CollectionStoragePath)!

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow DUC wallet reference from Dapper")
		self.walletBalance = self.walletReference.balance
		let vault <- self.walletReference.withdraw(amount: amount)

		let iou <- collectionRef.create(<- vault)
		collectionRef.deposit(<- iou)
	}

	post{
		self.walletBalance == self.walletReference.balance : "Token leakage"
	}
}

