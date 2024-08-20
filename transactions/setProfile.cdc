import "Profile"

transaction(avatar: String) {

    let profile : auth(Profile.Admin) &Profile.User?

    prepare(acct: auth (BorrowValue) &Account) {
        self.profile =acct.storage.borrow<auth(Profile.Admin) &Profile.User>(from:Profile.storagePath)
    }

    pre{
        self.profile != nil : "Cannot borrow reference to profile"
    }

    execute{
        self.profile!.setAvatar(avatar)
        self.profile!.emitUpdatedEvent()
    }
}

