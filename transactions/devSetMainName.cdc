import "Profile"
import "FIND"


transaction(name: String) {
    prepare(acct: auth(BorrowValue) &Account) {

        let profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!
        profile.setFindName(name)
    }
}

