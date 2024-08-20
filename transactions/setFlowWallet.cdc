import Admin from "../contracts/Admin.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction() {

    prepare(account: AuthAccount) {
        let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
        let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
        adminClient.setWallet(wallet)
    }
}

