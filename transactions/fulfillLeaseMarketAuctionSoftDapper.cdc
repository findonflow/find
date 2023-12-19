import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction(leaseName: String, amount:UFix64) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindLeaseMarketAuctionSoft.MarketBidCollection
	let requiredAmount: UFix64
	let mainDapperCoinVault: &FungibleToken.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: auth(BorrowValue) &Account, account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())

		self.bidsReference= account.storage.borrow<&FindLeaseMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())
		let item = FindLeaseMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, name: leaseName)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

		self.mainDapperCoinVault = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("Cannot borrow Dapper Coin vault from account storage. Type : ".concat(ft.type.identifier))
		self.balanceBeforeTransfer = self.mainDapperCoinVault.balance

		self.walletReference = dapper.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.requiredAmount = self.bidsReference.getBalance(leaseName)
	}

	pre{
		self.walletReference.balance > self.requiredAmount : "Your wallet does not have enough funds to pay for this item"
		self.requiredAmount == amount : "Amount needed to fulfill is ".concat(self.requiredAmount.toString()).concat(" you sent in ").concat(amount.toString())
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount)
		self.bidsReference.fulfillAuction(name: leaseName, vault: <- vault)
	}

	// Check that all dapper Coin was routed back to Dapper
	post {
		self.mainDapperCoinVault.balance == self.balanceBeforeTransfer: "Dapper Coin leakage"
	}
}

