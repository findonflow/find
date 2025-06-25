import "Profile"
import "FIND"


transaction(name: String) {

    let profile : auth(Profile.Admin) &Profile.User
    prepare(acct: auth(BorrowValue) &Account) {
        self.profile =acct.storage.borrow<auth(Profile.Admin) &Profile.User>(from:Profile.storagePath) ?? panic("Cannot borrow reference to profile")
    }

    execute{
        self.profile.setMainName(name)
    }
}

