
import Admin from "../contracts/Admin.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction() {
	prepare(account: AuthAccount) {
		let wallet=account.capabilities.get<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !wallet.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			let cap = account.capabilities.storage.issue<&{FUSD.Vault}>(/storage/fusdVault)
			account.capabilities.publish(cap, at: /public/fusdReceiver)
		}

		let adminClient=account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!
		adminClient.setPublicEnabled(true)
		adminClient.setWallet(wallet)
	}
}

