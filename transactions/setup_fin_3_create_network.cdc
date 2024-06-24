import "Admin"
import "FUSD"
import "FungibleToken"
import "FiatToken"

transaction() {
    prepare(account: auth (BorrowValue, SaveValue, StorageCapabilities, IssueStorageCapabilityController, PublishCapability) &Account) {

        let wallet=account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        let adminClient=account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from:Admin.AdminProxyStoragePath)!
        adminClient.setPublicEnabled(true)
        adminClient.setWallet(wallet)

        var usdcCap = account.capabilities.get<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if !usdcCap.check() {
            account.storage.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
            let cap = account.capabilities.storage.issue<&FiatToken.Vault>(FiatToken.VaultStoragePath)
            account.capabilities.publish(cap, at: FiatToken.VaultUUIDPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultReceiverPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultBalancePubPath)
        }

    }
}

