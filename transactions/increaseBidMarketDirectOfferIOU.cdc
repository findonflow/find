import FindMarketDirectOfferIOU from "../contracts/FindMarketDirectOfferIOU.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64, amount: UFix64) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketDirectOfferIOU.MarketBidCollection
	let balanceBeforeBid: UFix64

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferIOU.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferIOU.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketDirectOfferIOU.MarketBidCollection>())
		let item = FindMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, id: id)
		let ft = FTRegistry.getFTInfoByTypeIdentifier(item.getFtType().identifier) ?? panic("This FT is not supported by the Find Market yet. Type : ".concat(item.getFtType().identifier))
		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.balanceBeforeBid=self.walletReference.balance
	}

	pre {
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference.increaseBid(id: id, vault: <- vault)
	}

}

