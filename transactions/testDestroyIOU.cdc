import EscrowedIOweYou from "../contracts/EscrowedIOweYou.cdc"


transaction(id: UInt64) {

	prepare(account: AuthAccount) {
		let collectionRef = account.borrow<&EscrowedIOweYou.Collection>(from: EscrowedIOweYou.CollectionStoragePath)!
		let iou <- collectionRef.withdraw(id)

		destroy iou
	}

}

