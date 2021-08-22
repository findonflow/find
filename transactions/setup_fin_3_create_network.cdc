

import FUSD from "../contracts/standard/FUSD.cdc"
import FiNS from "../contracts/FiNS.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(leasePeriod: UFix64) {

	prepare(account: AuthAccount) {
		let wallet=account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !wallet.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let adminClient=account.borrow<&FiNS.AdminProxy>(from: FiNS.AdminProxyStoragePath)!

		adminClient.createNetwork(
			admin: account, 
			leasePeriod: leasePeriod,
			lockPeriod: leasePeriod / 2.0,
			secondaryCut: 0.025,
			defaultPrice: 5.0,
			lengthPrices: {1: 500.0, 2:500.0, 3: 500.0, 4:100.0},
			wallet: wallet)
		}
	}

