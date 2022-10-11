import Profile from "../contracts/Profile.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import IOweYou from "../contracts/IOweYou.cdc"
import EscrowedIOweYou from "../contracts/EscrowedIOweYou.cdc"


transaction(name: String, amount: UFix64) {

	prepare(account: AuthAccount) {

		let receiverCap=account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)

		if account.borrow<&EscrowedIOweYou.Collection>(from: EscrowedIOweYou.CollectionStoragePath) == nil {
			account.save<@EscrowedIOweYou.Collection>( <- EscrowedIOweYou.createEmptyCollection(receiverCap) , to: EscrowedIOweYou.CollectionStoragePath)
			account.link<&EscrowedIOweYou.Collection{IOweYou.CollectionPublic}>(EscrowedIOweYou.CollectionPublicPath, target: EscrowedIOweYou.CollectionStoragePath)
		}

		let collectionRef = account.borrow<&EscrowedIOweYou.Collection>(from: EscrowedIOweYou.CollectionStoragePath)!

		let ft = FTRegistry.getFTInfo(name) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(name))
		let walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath)!
		let vault <- walletReference.withdraw(amount: amount)

		let iou <- collectionRef.create(<- vault)
		collectionRef.deposit(<- iou)
	}
}

