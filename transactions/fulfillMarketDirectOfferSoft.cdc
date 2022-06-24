import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64, amount:UFix64) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection
	let requiredAmount:UFix64

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow direct offer soft bid collection")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)

		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))

	  self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")

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
}

