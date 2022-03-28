import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"

transaction(id: UInt64, amount: UFix64) {

	let walletReference : &FUSD.Vault
	let bidsReference: &FindMarketDirectOfferEscrow.MarketBidCollection?
	let balanceBeforeBid: UFix64

	prepare(account: AuthAccount) {
		self.walletReference = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("No FUSD wallet linked for this account")
		let tenant=FindMarket.getFindTenant()
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.MarketBidCollection>())!
		self.bidsReference= account.borrow<&FindMarketDirectOfferEscrow.MarketBidCollection>(from: storagePath)
		self.balanceBeforeBid=self.walletReference.balance
	}

	pre {
		self.bidsReference != nil : "This account does not have a bid collection"
		self.walletReference.balance > amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference!.increaseBid(id: id, vault: <- vault)
	}

	post {
		self.walletReference.balance == self.balanceBeforeBid - amount
	}
}

