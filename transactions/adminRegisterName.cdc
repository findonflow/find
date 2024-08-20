import "FIND"
import "Admin"
import "Profile"

transaction(names: [String], user: Address) {

    prepare(account: auth(BorrowValue) &Account) {

        let userAccount=getAccount(user)
        let profileCap = userAccount.capabilities.get<&{Profile.Public}>(Profile.publicPath)!
        let leaseCollectionCap=userAccount.capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)!
        let adminClient=account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

        for name in names {
            adminClient.register(name: name,  profile: profileCap, leases: leaseCollectionCap)
        }
    }
}

