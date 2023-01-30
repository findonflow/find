import WearablesDev from "../contracts/community/WearablesDev.cdc"

transaction(receiver: Address,) {
	prepare(account: AuthAccount) {
		WearablesDev.mintWearablesForTest(receiver: receiver)
	}
}
