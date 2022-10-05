import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindIOU from "../contracts/FindIOU.cdc"


transaction(name: String, amount: UFix64) {
	
	prepare(account: AuthAccount) {
		let path = StoragePath(identifier: name.concat("_Find_IOU"))!
		let iou <- account.load<@FindIOU.EscrowedIOU>(from: path) ?? panic("Cannot load IOU from storage path")

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		let walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)!
		let vault <- walletReference.withdraw(amount: amount)

		iou.topUp(<- vault)
		account.save(<- iou, to: path)
	}
}

