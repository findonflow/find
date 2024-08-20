import "FindMarketAuctionSoft"
import "FungibleToken"
import "FTRegistry"
import "FindMarket"

transaction(id: UInt64, amount: UFix64) {

	let bidsReference: auth(FindMarketAuctionSoft.Buyer) &FindMarketAuctionSoft.MarketBidCollection


	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<auth(FindMarketAuctionSoft.Buyer) &FindMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
	  	let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionSoft.MarketBidCollection>())
		let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
		if !ft.tag.contains("dapper") {
			let walletReference = account.storage.borrow<&{FungibleToken.Vault}>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		}
	}

	execute {
		self.bidsReference.increaseBid(id: id, increaseBy: amount)
	}

}

