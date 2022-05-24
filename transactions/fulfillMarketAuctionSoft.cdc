import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarket from "../contracts/FindMarket.cdc"

transaction(marketplace:Address, id: UInt64, amount:UFix64) {

	let walletReference : &FungibleToken.Vault
	let bidsReference: &FindMarketAuctionSoft.MarketBidCollection
	let requiredAmount: UFix64

	prepare(account: AuthAccount) {
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())

		self.bidsReference= account.borrow<&FindMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("This account does not have a bid collection")

		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketAuctionSoft.MarketBidCollection>())
		let bid = FindMarket.getBid(tenant:marketplace, address: account.address, marketOption: marketOption, id:id, getNFTInfo:false)
		if bid==nil {
			panic("Cannot fulfill market auction on ghost listing")
		}
		let ftIdentifier = bid!.item.ftTypeIdentifier
		let ft = FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier)!

		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
		self.requiredAmount = self.bidsReference.getBalance(id)
	}

	pre{
		self.walletReference.balance > self.requiredAmount : "Your wallet does not have enough funds to pay for this item"
		self.requiredAmount == amount : "Amount needed to fulfill is ".concat(self.requiredAmount.toString()).concat(" you sent in ").concat(amount.toString())
	}

	execute {
		let vault <- self.walletReference.withdraw(amount: amount) 
		self.bidsReference.fulfillAuction(id: id, vault: <- vault)
	}
}

