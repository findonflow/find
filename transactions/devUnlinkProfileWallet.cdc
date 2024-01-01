import Profile from "../contracts/Profile.cdc"
transaction() {
    prepare(account: auth(UnpublishCapability) &Account) {
        account.capabilities.unpublish(Profile.publicReceiverPath)
    }
}
