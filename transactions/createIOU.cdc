import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindIOU from "../contracts/FindIOU.cdc"


transaction(name: String, amount: UFix64) {

	prepare(account: AuthAccount) {

		if account.borrow<&FindIOU.Collection>(from: FindIOU.CollectionStoragePath) == nil {
			account.save<@FindIOU.Collection>( <- FindIOU.createEmptyCollection() , to: FindIOU.CollectionStoragePath)
			account.link<&FindIOU.Collection{FindIOU.CollectionPublic}>(FindIOU.CollectionPublicPath, target: FindIOU.CollectionStoragePath)
		}

		let collectionRef = account.borrow<&FindIOU.Collection>(from: FindIOU.CollectionStoragePath)!

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		let walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)!
		let vault <- walletReference.withdraw(amount: amount)

		let iou <- collectionRef.create(<- vault)
		collectionRef.deposit(<- iou)
	}
}

