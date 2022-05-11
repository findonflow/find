import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

transaction(id: UInt64) {

	let walletReference : &FungibleToken.Vault
	let balanceBeforeFulfill: UFix64
	let bidsReference: &FindMarketAuctionSoft.MarketBidCollection
	let amount: UFix64

	prepare(account: AuthAccount) {
		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())!

		self.bidsReference= account.borrow<&FindMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")

		let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketAuctionSoft.MarketBidCollection>())
		let bid = FindMarketOptions.getFindBid(address: account.address, marketOption: marketOption, id:id)
		if bid==nil {
			panic("Cannot fulfill market auction on ghost listing")
		}
		let ftIdentifier = bid!.item.ftTypeIdentifier
		let ft = FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier)!

		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.balanceBeforeFulfill=self.walletReference.balance
		self.amount = self.bidsReference.getBalance(id)
	}

	pre{
		self.walletReference.balance > self.amount : "Your wallet does not have enough funds to pay for this item"
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: self.amount) 
		self.bidsReference.fulfillAuction(id: id, vault: <- vault)
	}

	post{
		self.walletReference.balance == self.balanceBeforeFulfill - self.amount
	}
}

//TODO: Fix post and pre
//Ben : Tried to implement the post and pre
