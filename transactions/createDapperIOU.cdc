import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindIOU from "../contracts/FindIOU.cdc" 


transaction(name: String, amount: UFix64) {

	let walletReference : &FungibleToken.Vault
	let walletBalance : UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow DUC wallet reference from Dapper")
		self.walletBalance = self.walletReference.balance
		let vault <- self.walletReference.withdraw(amount: amount)

		let iou <- FindIOU.createIOU(<- vault)
		account.save(<- iou, to: StoragePath(identifier: name.concat("_Find_IOU"))!)
	}

	post{
		self.walletBalance == self.walletReference.balance : "Token leakage"
	}
}

