import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindIOU from "../contracts/FindIOU.cdc"
import TokenForwarding from "../contracts/standard/TokenForwarding.cdc"


transaction(name: String) {

	let walletReference : &FungibleToken.Vault
	let walletBalance : UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let iou <- account.load<@FindIOU.EscrowedIOU>(from: StoragePath(identifier: name.concat("_Find_IOU"))!) ?? panic("Cannot load IOU from storage path")

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow DUC wallet reference from Dapper")
		self.walletBalance = self.walletReference.balance
		let returningVault <- self.walletReference.withdraw(amount: iou.balance)

		let vault <- FindIOU.redeemIOU(iou: <- iou, vault: <- returningVault)

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

