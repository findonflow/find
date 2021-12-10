
import Admin from "../contracts/Admin.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
import Artifact from "../contracts/Artifact.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"
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
		adminClient.setWallet(wallet)
		adminClient.setPublicEnabled(true)

	}
}

