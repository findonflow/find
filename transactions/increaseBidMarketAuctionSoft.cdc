import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

//TODO: this needs work for DUC
transaction(id: UInt64, amount: UFix64) {

	let bidsReference: &FindMarketAuctionSoft.MarketBidCollection
	let walletReference : &FUSD.Vault

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getFindTenant()
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())!
		self.bidsReference= account.borrow<&FindMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		self.walletReference = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD wallet linked for this account")
	}

	execute {
		self.bidsReference.increaseBid(id: id, increaseBy: amount)
	}
}

