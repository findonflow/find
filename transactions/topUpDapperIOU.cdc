import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindIOU from "../contracts/FindIOU.cdc"


transaction(name: String, amount: UFix64) {


	let walletReference : &FungibleToken.Vault
	let walletBalance : UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let path = StoragePath(identifier: name.concat("_Find_IOU"))!
		let iou <- account.load<@FindIOU.EscrowedIOU>(from: path) ?? panic("Cannot load IOU from storage path")

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath)!
		self.walletBalance = self.walletReference.balance
		let vault <- self.walletReference.withdraw(amount: amount)

		iou.topUp(<- vault)
		account.save(<- iou, to: path)
	}

	post{
		self.walletBalance == self.walletReference.balance : "Token leakage"
	}
}

