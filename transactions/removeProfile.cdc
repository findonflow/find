import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

transaction() {
	prepare(acct: AuthAccount) {
			acct.unlink(Profile.publicPath)
			destroy <- acct.load<@AnyResource>(from:Profile.storagePath)

			acct.unlink(FIND.BidPublicPath)
			destroy <- acct.load<@AnyResource>(from:FIND.BidStoragePath)

			acct.unlink(FIND.LeasePublicPath)
			destroy <- acct.load<@AnyResource>(from:FIND.LeaseStoragePath)
	}
}
