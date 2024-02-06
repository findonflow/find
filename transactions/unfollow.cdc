import "FIND"
import "Profile"

// array of [User in string (find name or address)]
transaction(unfollows:[String]) {

    let profile : auth(Profile.Owner) &Profile.User

    prepare(account: auth(BorrowValue, Profile.Owner) &Account) {

        self.profile =account.storage.borrow<auth(Profile.Owner) &Profile.User>(from:Profile.storagePath) ?? panic("Cannot borrow reference to profile")

    }

    execute{
        for key in unfollows {
            let user = FIND.resolve(key) ?? panic(key.concat(" cannot be resolved. It is either an invalid .find name or address"))
            self.profile.unfollow(user)
        }
    }
}

