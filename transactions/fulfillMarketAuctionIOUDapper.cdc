import FindMarketAuctionIOUDapper from "../contracts/FindMarketAuctionIOUDapper.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(marketplace:Address, owner: String, id: UInt64) {

	let saleItem : Capability<&FindMarketAuctionIOUDapper.SaleItemCollection{FindMarketAuctionIOUDapper.SaleItemCollectionPublic}>?
	let requiredAmount: UFix64
	let mainDapperVault: &FungibleToken.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let resolveAddress = FIND.resolve(owner)
		if resolveAddress == nil { 
			panic("The address input is not a valid name nor address. Input : ".concat(owner))
		}
		let address = resolveAddress!
		self.saleItem = FindMarketAuctionIOUDapper.getSaleItemCapability(marketplace:marketplace, user:address)

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionIOUDapper.MarketBidCollection>())
		let item = FindMarket.assertOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
	
		self.mainDapperVault = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow Dapper vault from account storage")
		self.balanceBeforeTransfer = self.mainDapperVault.balance
		self.requiredAmount = item.getBalance()
	}

	pre{
		self.saleItem != nil : "This saleItem capability does not exist. Sale item ID: ".concat(id.toString())
		self.saleItem!.check() : "Cannot borrow reference to saleItem. Sale item ID: ".concat(id.toString())
	}

	execute {
		let vault <- self.mainDapperVault.withdraw(amount : self.requiredAmount)
		self.saleItem!.borrow()!.fulfillAuction(id:id, vault: <- vault)
	}

	post {
		self.mainDapperVault.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
	}
}
