import "Admin"
import "FUSD"
import "FungibleToken"

transaction() {
    prepare(account: auth (BorrowValue, StorageCapabilities) &Account) {

        let wallet=account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)!
        let adminClient=account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from:Admin.AdminProxyStoragePath)!
        adminClient.setPublicEnabled(true)
        adminClient.setWallet(wallet)
    }
}

