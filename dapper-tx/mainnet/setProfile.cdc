import Profile from 0x097bafa4e0b48eef

transaction(avatar: String) {

    let profile : &Profile.User?

    prepare(acct: AuthAccount) {
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
