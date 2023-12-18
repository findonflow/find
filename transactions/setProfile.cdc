import "Profile"

transaction(avatar: String) {

    let profile : &Profile.User?

    prepare(acct: auth (BorrowValue) &Account) {
        self.profile =acct.storage.borrow<&Profile.User>(from:Profile.storagePath)!
    }

    pre{
        self.profile != nil : "Cannot borrow reference to profile"
    }

    execute{

        //TODO: entitlement!
        self.profile!.setAvatar(avatar)
        self.profile!.emitUpdatedEvent()
    }
}

