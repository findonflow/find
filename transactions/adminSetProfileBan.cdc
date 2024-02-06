import "Profile"
import "FIND"

transaction(user: String) {
    prepare(account: auth(BorrowValue, Profile.Owner) &Account) {
        let profile =account.storage.borrow<auth(Profile.Owner) &Profile.User>(from:Profile.storagePath)!
        let address =FIND.resolve(user) ?? panic("Not a registered name or valid address.")
        profile.addBan(address)
    }
}

