import Profile from "../contracts/Profile.cdc"


transaction() {
	prepare(account: AuthAccount) {
		account.unlink(Profile.publicReceiverPath)
	}
}
