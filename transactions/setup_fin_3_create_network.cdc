import "Admin"
import "FungibleToken"

transaction() {
    prepare(account: auth (BorrowValue, SaveValue, StorageCapabilities, IssueStorageCapabilityController, PublishCapability) &Account) {

        let wallet=account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let adminClient=account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from:Admin.AdminProxyStoragePath)!
        adminClient.setPublicEnabled(true)
        adminClient.setWallet(wallet)
    }
}

