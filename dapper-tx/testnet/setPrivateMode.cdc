import Profile from 0x35717efbbce11c74

transaction(mode: Bool) {

    let profile : &Profile.User?

    prepare(acct: AuthAccount) {
        self.profile =acct.borrow<&Profile.User>(from:Profile.storagePath)
    }

    pre{
        self.profile != nil : "Cannot borrow reference to profile"
    }

    execute{
        self.profile!.setPrivateMode(mode)
        self.profile!.emitUpdatedEvent()
    }
}
