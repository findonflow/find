import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import DapperUtilityCoin from "../contracts/standard/DapperUtilityCoin.cdc"

transaction(marketplace:Address, ids: [UInt64], amounts:[UFix64]) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection
	var requiredAmount:UFix64
	let balanceBeforeTransfer: UFix64
	var totalAmount: UFix64

	prepare(dapper: AuthAccount, account: AuthAccount) {

		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow direct offer soft bid collection")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
	  	self.walletReference = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault) ?? panic("Cannot borrow DapperUtilityCoin vault from account storage")
		self.balanceBeforeTransfer = self.walletReference.balance

		var counter = 0
		self.totalAmount = 0.0
		self.requiredAmount = 0.0
		while counter < ids.length {
			let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: ids[counter])
			self.requiredAmount = self.requiredAmount + self.bidsReference.getBalance(ids[counter])
			self.totalAmount = self.totalAmount + amounts[counter]
			counter = counter + 1
		}
	}

	pre {
		self.walletReference.balance > self.requiredAmount : "Your wallet does not have enough funds to pay for this item"
		self.requiredAmount == self.totalAmount : "Amount needed to fulfill is ".concat(self.totalAmount.toString())
	}

	execute {
		var counter = 0
		while counter < ids.length {
			let vault <- self.walletReference.withdraw(amount: amounts[counter]) 
			self.bidsReference.fulfillDirectOffer(id: ids[counter], vault: <- vault)
			counter = counter + 1 
		}
	}

	// Check that all dapperUtilityCoin was routed back to Dapper
	post {
		self.walletReference.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
	}
}

