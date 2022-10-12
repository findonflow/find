import FindMarketAuctionIOUDapper from "../contracts/FindMarketAuctionIOUDapper.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64, amount: UFix64) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketAuctionIOUDapper.MarketBidCollection
	let balanceBeforeBid: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		// Get the accepted vault type from BidInfo
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionIOUDapper.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketAuctionIOUDapper.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionIOUDapper.MarketBidCollection>())
		let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.balanceBeforeBid = self.walletReference.balance
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference.increaseBid(id: id, vault: <- vault)
	}

	post {
		self.walletReference.balance == self.balanceBeforeBid: "Dapper Coin leakage"
	}
}

