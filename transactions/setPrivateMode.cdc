import Profile from "../contracts/Profile.cdc"

transaction(mode: Bool) {

    let profile : auth(Profile.Owner) &Profile.User?

    prepare(acct: auth(Profile.Owner, BorrowValue) &Account) {
        self.profile =acct.storage.borrow<auth(Profile.Owner) &Profile.User>(from:Profile.storagePath)
    }

    pre{
        self.profile != nil : "Cannot borrow reference to profile"
    }

    execute{
        self.profile!.setPrivateMode(mode)
        self.profile!.emitUpdatedEvent()
    }
}

