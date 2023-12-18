import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) main(user: Address) : Bool {

	let account=getAccount(user)
	if account.balance == 0.0 {
		return false
	}
	let leaseCap=account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
	let profileCap=account.getCapability<&{Profile.Public}>(Profile.publicPath)

	return leaseCap.check() && profileCap.check()

}
