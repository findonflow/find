import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(id: UInt64) {

	let walletReference : &FUSD.Vault
	let balanceBeforeFulfill: UFix64
	let bidsReference: &FindMarketAuctionSoft.MarketBidCollection

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getFindTenant()
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())!

		self.walletReference = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD wallet linked for this account")
		self.balanceBeforeFulfill=self.walletReference.balance
		self.bidsReference= account.borrow<&FindMarketAuctionSoft.MarketBidCollection>(from: storagePath)!
	}

	execute {
		let amount = self.bidsReference.getBalance(id)
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference.fulfillAuction(id: id, vault: <- vault)
	}
}

//TODO: Fix post and pre
