import "Profile"

transaction(mode: Bool) {

    let profile : auth(Profile.Admin) &Profile.User?

    prepare(acct: auth(Profile.Admin, BorrowValue) &Account) {
        self.profile =acct.storage.borrow<auth(Profile.Admin) &Profile.User>(from:Profile.storagePath)
    }

    pre{
        self.profile != nil : "Cannot borrow reference to profile"
    }

    execute{
        self.profile!.setPrivateMode(mode)
        self.profile!.emitUpdatedEvent()
    }
}

