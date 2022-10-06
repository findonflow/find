import FindIOU from "../contracts/FindIOU.cdc"


transaction(id: UInt64) {

	prepare(account: AuthAccount) {
		let collectionRef = account.borrow<&FindIOU.Collection>(from: FindIOU.CollectionStoragePath)!
		let iou <- collectionRef.withdraw(id)

		destroy iou
	}

}

