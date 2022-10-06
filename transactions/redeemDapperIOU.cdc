import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindIOU from "../contracts/FindIOU.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"


transaction(id: UInt64) {

	let walletReference : &FungibleToken.Vault
	let walletBalance : UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let collectionRef = account.borrow<&FindIOU.Collection>(from: FindIOU.CollectionStoragePath)!
		let iouRef = collectionRef.borrowIOU(id)
		let iouBalance = iouRef.balance
		let vaultType = iouRef.vaultType.identifier

		let ft = FTRegistry.getFTInfo(vaultType) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(vaultType))
		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow DUC wallet reference from Dapper")
		self.walletBalance = self.walletReference.balance
		let redeemingVault <- self.walletReference.withdraw(amount: iouBalance)

		let vault <- collectionRef.redeem(id:id, vault: <- redeemingVault)

		var ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		if !ducReceiver.check() {
			// Create a new Forwarder resource for DUC and store it in the new account's storage
			let ducForwarder <- TokenForwarding.createNewForwarder(recipient: dapper.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver))
			account.save(<-ducForwarder, to: /storage/dapperUtilityCoinReceiver)
			// Publish a Receiver capability for the new account, which is linked to the DUC Forwarder
			account.link<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver,target: /storage/dapperUtilityCoinReceiver)
			ducReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/dapperUtilityCoinReceiver)
		}

		ducReceiver.borrow()!.deposit(from: <- vault)

	}

	post{
		self.walletBalance == self.walletReference.balance : "Token leakage"
	}
}

