import Profile from "../contracts/Profile.cdc"


transaction() {
	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		account.unlink(Profile.publicReceiverPath)
	}
}
