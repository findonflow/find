import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

//Check the status of a fin user
pub fun main(user: Address) : Bool {

	let account=getAccount(user)
	let leaseCap=account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
	let profileCap=account.getCapability<&{Profile.Public}>(Profile.publicPath)

	return leaseCap.check() && profileCap.check()

}
