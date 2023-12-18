import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(id: UInt64, amount: UFix64) {

	let bidsReference: &FindMarketAuctionSoft.MarketBidCollection


	prepare(account: auth(BorrowValue)  AuthAccountAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
	  	let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionSoft.MarketBidCollection>())
		let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
		if !ft.tag.contains("dapper") {
			let walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		}
	}

	execute {
		self.bidsReference.increaseBid(id: id, increaseBy: amount)
	}

}

