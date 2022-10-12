import FindMarketAuctionIOUDapper from "../contracts/FindMarketAuctionIOUDapper.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"

transaction(marketplace:Address, id: UInt64) {

	let bidsReference : &FindMarketAuctionIOUDapper.MarketBidCollection
	let mainDapperVault: &FungibleToken.Vault
	let balanceBeforeTransfer: UFix64
	let requiredAmount: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionIOUDapper.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketAuctionIOUDapper.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow reference to bid collection.")

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionIOUDapper.MarketBidCollection>())
		let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
	
		self.mainDapperVault = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow Dapper vault from account storage")
		self.balanceBeforeTransfer = self.mainDapperVault.balance
		self.requiredAmount = item.getBalance()
	}

	execute{
		let vault <- self.mainDapperVault.withdraw(amount : self.requiredAmount)
		self.bidsReference.fulfillAuction(id: id, vault: <- vault)
	}

	post {
		self.mainDapperVault.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
	}
}
