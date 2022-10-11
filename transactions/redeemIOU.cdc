import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import EscrowedIOweYou from "../contracts/EscrowedIOweYou.cdc"


transaction(id: UInt64) {

	prepare(account: AuthAccount) {
		let collectionRef = account.borrow<&EscrowedIOweYou.Collection>(from: EscrowedIOweYou.CollectionStoragePath)!
		let vaultType = collectionRef.borrowIOU(id).vaultType.identifier

		let iou <- collectionRef.withdraw(id)
		collectionRef.depositAndRedeemToAccount(token: <- iou, vault: nil)
	}
}

