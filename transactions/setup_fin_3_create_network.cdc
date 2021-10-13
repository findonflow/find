
import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
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

		let adminClient=account.borrow<&FIND.AdminProxy>(from: FIND.AdminProxyStoragePath)!
		adminClient.setWallet(wallet)
		adminClient.setPublicEnabled(true)
	}
}

