import "Profile"

//THIS always fails
transaction(address:Address, newName: String) {

    prepare(account: &Account) {
        let otherAccount=getAccount(address)
        let otherProfile=otherAccount.capabilities.borrow<&Profile.User>(Profile.publicPath)!
        otherProfile.setName(newName)
        otherProfile.emitUpdatedEvent()
    }
}

