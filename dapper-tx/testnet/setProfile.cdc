import Profile from 0x35717efbbce11c74

transaction(avatar: String) {

    let profile : &Profile.User?

    prepare(acct: auth(BorrowValue)  AuthAccountAccount) {
        self.profile =acct.borrow<&Profile.User>(from:Profile.storagePath)
    }

    pre{
        self.profile != nil : "Cannot borrow reference to profile"
    }

    execute{
        self.profile!.setAvatar(avatar)
        self.profile!.emitUpdatedEvent()
    }
}
