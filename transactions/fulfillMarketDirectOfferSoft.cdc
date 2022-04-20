import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

//TODO: should these include the amount for safety reason, i belive they should
transaction(id: UInt64) {

	let walletReference : &FUSD.Vault
	let balanceBeforeFulfill: UFix64
	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())!

		self.walletReference = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD wallet linked for this account")
		self.balanceBeforeFulfill=self.walletReference.balance
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath)!
	}

	execute {
		let amount = self.bidsReference.getBalance(id)
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference.fulfillDirectOffer(id: id, vault: <- vault)
	}
}

