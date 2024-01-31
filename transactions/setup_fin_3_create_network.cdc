import Admin from "../contracts/Admin.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"

transaction() {
    prepare(account: auth (BorrowValue, SaveValue, StorageCapabilities, IssueStorageCapabilityController, PublishCapability) &Account) {

        let wallet=account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)!
        let adminClient=account.storage.borrow<auth(Admin.Owner) &Admin.AdminProxy>(from:Admin.AdminProxyStoragePath)!
        adminClient.setPublicEnabled(true)
        adminClient.setWallet(wallet)

        var usdcCap = account.capabilities.get<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
        if usdcCap == nil {
            account.storage.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
            let cap = account.capabilities.storage.issue<&FiatToken.Vault>(FiatToken.VaultStoragePath)
            account.capabilities.publish(cap, at: FiatToken.VaultUUIDPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultReceiverPubPath)
            account.capabilities.publish(cap, at: FiatToken.VaultBalancePubPath)
        }

    }
}

