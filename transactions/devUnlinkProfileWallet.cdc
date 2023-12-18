import Profile from "../contracts/Profile.cdc"


transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		account.unlink(Profile.publicReceiverPath)
	}
}
