import Profile from "../contracts/Profile.cdc"

transaction(avatar: String) {

    let profile : auth(Profile.Owner) &Profile.User?

    prepare(acct: auth (BorrowValue) &Account) {
        self.profile =acct.storage.borrow<auth(Profile.Owner) &Profile.User>(from:Profile.storagePath)!
    }

    pre{
        self.profile != nil : "Cannot borrow reference to profile"
    }

    execute{
        self.profile!.setAvatar(avatar)
        self.profile!.emitUpdatedEvent()
    }
}

