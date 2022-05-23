import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

//TODO: should these include the amount for safety reason, i belive they should
transaction(marketplace:Address, id: UInt64) {

	let walletReference : &FungibleToken.Vault
	let balanceBeforeFulfill: UFix64
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection

	prepare(account: AuthAccount) {
		let tenant=FindMarketOptions.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Cannot borrow direct offer soft bid collection")
		let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		let bid = FindMarketOptions.getBid(tenant:marketplace, address: account.address, marketOption: marketOption, id:id)
		if bid==nil {
			panic("Cannot fulfill market offer on ghost listing")
		}

		let ftIdentifier= bid!.item.ftTypeIdentifier
		let ft = FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier)!

	self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.balanceBeforeFulfill=self.walletReference.balance

	}

	execute {
		let amount = self.bidsReference.getBalance(id)
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference.fulfillDirectOffer(id: id, vault: <- vault)
	}
}

