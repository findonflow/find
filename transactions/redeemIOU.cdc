import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindIOU from "../contracts/FindIOU.cdc"


transaction(name: String) {

	prepare(account: AuthAccount) {
		let iou <- account.load<@FindIOU.EscrowedIOU>(from: StoragePath(identifier: name.concat("_Find_IOU"))!) ?? panic("Cannot load IOU from storage path")

		let emptyVault <- iou.createEmptyVault()
		let vault <- FindIOU.redeemIOU(iou: <- iou, vault: <- emptyVault)

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		let walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)!
		walletReference.deposit(from: <- vault)
	}
}

