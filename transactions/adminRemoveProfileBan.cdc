import "Profile"
import "FIND"

transaction(user: String) {
    prepare(acct: auth(BorrowValue) &Account) {
        let profile =acct.storage.borrow<auth(Profile.Admin) &Profile.User>(from:Profile.storagePath)!
        let address =FIND.resolve(user) ?? panic("Not a registered name or valid address.")
        profile.removeBan(address)
    }
}

