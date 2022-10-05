import FindIOU from "../contracts/FindIOU.cdc"


transaction(name: String) {

	prepare(account: AuthAccount) {
		let iou <- account.load<@FindIOU.EscrowedIOU>(from: StoragePath(identifier: name.concat("_Find_IOU"))!) ?? panic("Cannot load IOU from storage path")

		destroy iou
	}

}

