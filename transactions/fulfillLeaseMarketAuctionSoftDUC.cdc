import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"

transaction(leaseName: String, amount:UFix64) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindLeaseMarketAuctionSoft.MarketBidCollection
	let requiredAmount: UFix64
	let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault
	let balanceBeforeTransfer: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {
		let marketplace = FindMarket.getTenantAddress("findLease")!
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())

		self.bidsReference= account.borrow<&FindLeaseMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketAuctionSoft.MarketBidCollection>())
		let item = FindLeaseMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, name: leaseName)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
	
		// There should be no need to assert this, there will be no listing in other tokens for Dapper wallet.
		// if ft.type != Type<@DapperUtilityCoin.Vault>(){
		// 	panic("This item is not listed for Dapper Wallets. Please fulfill in with other wallets.")
		// }
		self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage")
		self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance

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

	// Check that all dapperUtilityCoin was routed back to Dapper
	post {
		self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}

