import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

//TODO: this needs work for DUC
transaction(id: UInt64, amount: UFix64) {

	let bidsReference: &FindMarketAuctionSoft.MarketBidCollection
	let walletReference : &FungibleToken.Vault

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())!
		self.bidsReference= account.borrow<&FindMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")

		// get Bidding Fungible Token Vault
		let ftIdentifier = self.bidsReference.getBid(id).item.ftTypeIdentifier

		let ft = FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier)!

		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
	}
	//Ben: No checking on whether the totalAmount < walletBalance yet
	execute {
		self.bidsReference.increaseBid(id: id, increaseBy: amount)
	}

}

