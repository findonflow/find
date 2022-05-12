import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketAuctionSoft from "../contracts/FindMarketAuctionSoft.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

transaction(id: UInt64, amount: UFix64) {

	let bidsReference: &FindMarketAuctionSoft.MarketBidCollection
	let walletReference : &FungibleToken.Vault
	let oldAmount:UFix64

	prepare(account: AuthAccount) {
		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let storagePath=tenant.getStoragePath(Type<@FindMarketAuctionSoft.MarketBidCollection>())!
		self.bidsReference= account.borrow<&FindMarketAuctionSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
	  	let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketAuctionSoft.MarketBidCollection>())
		let bid = FindMarketOptions.getFindBid(address: account.address, marketOption: marketOption, id:id)
		if bid==nil {
			panic("This bid is on a ghostlisting, so you should cancel the original bid and get your funds back")
		}
		let item= bid!.item
		self.oldAmount=item.amount!
		let ftIdentifier = item.ftTypeIdentifier
		let ft = FTRegistry.getFTInfoByTypeIdentifier(ftIdentifier)!

		self.walletReference = account.borrow<&FungibleToken.Vault>(from: ft.vaultPath) ?? panic("No suitable wallet linked for this account")
	}

	pre {
		self.walletReference.balance > self.oldAmount+amount : "Wallet must have required funds"
	}
	execute {
		self.bidsReference.increaseBid(id: id, increaseBy: amount)
	}

}

