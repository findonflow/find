import Profile from "../contracts/Profile.cdc"

transaction() {
	prepare(acct: AuthAccount) {
			acct.unlink(Profile.publicPath)
			destroy <- acct.load<@AnyResource>(from:Profile.storagePath)
	}
}
