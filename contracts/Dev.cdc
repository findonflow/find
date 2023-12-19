// This contract is for Development purpose only
// DO NOT DEPLOY TO TESTNET OR MAINNET

import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

access(all) contract Dev {
	access(all) getPaymentWallet(addr: Address, ftType: String, path: PublicPath, panicOnFailCheck: Bool) : &{FungibleToken.Receiver} {
		let account = getAccount(addr)
		let ftInfo = FTRegistry.getFTInfo(ftType)!
		let cap = account.getCapability<&{FungibleToken.Receiver}>(path)
		return FindMarket.getPaymentWallet(cap, ftInfo, panicOnFailCheck: panicOnFailCheck)
	}
}
