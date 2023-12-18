import FIND from "../contracts/FIND.cdc"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		destroy account.load<@FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
	}
}
