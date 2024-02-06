// This contract is for Development purpose only
// DO NOT DEPLOY TO TESTNET OR MAINNET

import "FindMarket"
import "FTRegistry"
import "FungibleToken"

access(all) contract Dev {
    access(all) fun getPaymentWallet(addr: Address, ftType: String, path: PublicPath, panicOnFailCheck: Bool) : &{FungibleToken.Receiver} {
        let account = getAccount(addr)
        let ftInfo = FTRegistry.getFTInfo(ftType)!
        let cap = account.capabilities.get<&{FungibleToken.Receiver}>(path)!
        return FindMarket.getPaymentWallet(cap, ftInfo, panicOnFailCheck: panicOnFailCheck)
    }
}
