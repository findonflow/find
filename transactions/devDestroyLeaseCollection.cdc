import FIND from "../contracts/FIND.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		destroy account.load<@FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
	}
}
