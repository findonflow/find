import "Profile"
transaction() {
    prepare(account: auth(UnpublishCapability) &Account) {
        account.capabilities.unpublish(Profile.publicReceiverPath)
    }
}
