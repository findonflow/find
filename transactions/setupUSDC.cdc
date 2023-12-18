import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"

transaction() {

    prepare(signer: auth(BorrowValue)  AuthAccountAccount) {

        // Return early if the account already stores a FiatToken Vault
        if signer.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath) != nil {
            return
        }

        signer.save( <-FiatToken.createEmptyVault(), to: FiatToken.VaultStoragePath)
        signer.link<&FiatToken.Vault{FungibleToken.Receiver}>( FiatToken.VaultReceiverPubPath, target: FiatToken.VaultStoragePath)
        signer.link<&FiatToken.Vault{FiatToken.ResourceId}>( FiatToken.VaultUUIDPubPath, target: FiatToken.VaultStoragePath)
        signer.link<&FiatToken.Vault{FungibleToken.Balance}>( FiatToken.VaultBalancePubPath, target: FiatToken.VaultStoragePath)

    }
}

