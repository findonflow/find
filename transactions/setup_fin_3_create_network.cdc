
import Admin from "../contracts/Admin.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction() {

    prepare(account: AuthAccount) {
        let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
        if !wallet.check() {
            let fusd <- FUSD.createEmptyVault()
            account.save(<- fusd, to: /storage/fusdVault)
            account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
            account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
        }

        let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
        adminClient.setPublicEnabled(true)
        adminClient.setWallet(wallet)

        // Return early if the account already stores a FiatToken Vault
        if account.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil {
            return
        }

        account.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
        account.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
        account.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
        account.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target: FiatToken.VaultStoragePath)


    }
}

