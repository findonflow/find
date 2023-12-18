import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(id: UInt64, amount:UFix64) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection
	let requiredAmount:UFix64
	let mainDapperCoinVault: &FungibleToken.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: auth(BorrowValue)  AuthAccountAccount, account: auth(BorrowValue)  AuthAccountAccount) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow direct offer soft bid collection")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		self.mainDapperCoinVault = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow Dapper Coin vault from account storage. Type : ".concat(ft.type.identifier))
		self.balanceBeforeTransfer = self.mainDapperCoinVault.balance

	  	self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

		self.requiredAmount = self.bidsReference.getBalance(id)
	}

	pre {
		self.walletReference.balance > self.requiredAmount : "Your wallet does not have enough funds to pay for this item"
		self.requiredAmount == amount : "Amount needed to fulfill is ".concat(amount.toString())
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		self.bidsReference.fulfillDirectOffer(id: id, vault: <- vault)
	}

	// Check that all dapper Coin was routed back to Dapper
	post {
		self.mainDapperCoinVault.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
	}
}

