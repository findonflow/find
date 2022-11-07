import FIND from "../contracts/FIND.cdc"


transaction() {
	prepare(account: AuthAccount) {
		destroy account.load<@FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
	}
}
