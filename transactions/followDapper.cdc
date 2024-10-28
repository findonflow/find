import "FungibleToken"
import "FlowToken"
import "FIND"
import "Profile"

// map of {User in string (find name or address) : [tag]}
transaction(follows:{String : [String]}) {

    let profile : &Profile.User

    prepare(account: auth(BorrowValue) &Account) {

        self.profile =account.storage.borrow<&Profile.User>(from:Profile.storagePath) ?? panic("You do not have a profile set up, initialize the user first")

        let leaseCollection = account.capabilities.get<&{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
        if !leaseCollection.check() {
            account.storage.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
            let cap = account.capabilities.storage.issue<&FIND.LeaseCollection>(FIND.LeaseStoragePath)
            account.capabilities.publish(cap, at: FIND.LeasePublicPath)
        }
    }

    execute{
        for key in follows.keys {
            let user = FIND.resolve(key) ?? panic(key.concat(" cannot be resolved. It is either an invalid .find name or address"))
            let tags = follows[key]!
            self.profile.follow(user, tags: tags)
        }
    }
}

