import "Profile"
import "FIND"

access(all) fun main(user: Address) : Bool {

    let account=getAccount(user)
    if account.balance == 0.0 {
        return false
    }
    let leaseCap=account.capabilities.get<&FIND.LeaseCollection>(FIND.LeasePublicPath)
    let profileCap = account.capabilities.get<&Profile.User>(Profile.publicPath)

    return leaseCap.check() && profileCap.check()

}
