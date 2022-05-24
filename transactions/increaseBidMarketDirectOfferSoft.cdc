import FindMarketDirectOfferSoft from "../contracts/FindMarketDirectOfferSoft.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FindMarketOptions from "../contracts/FindMarketOptions.cdc"

//TODO: this needs work for DUC
//TODO: this will not work for DUC, we need totally seperate TX for them or we need to just not check bid balance.
transaction(marketplace: Address, id: UInt64, amount: UFix64) {

	let bidsReference: &FindMarketDirectOfferSoft.MarketBidCollection

	prepare(account: AuthAccount) {
		let tenant=FindMarketOptions.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.borrow<&FindMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
  	let marketOption = FindMarketOptions.getMarketOptionFromType(Type<@FindMarketDirectOfferSoft.MarketBidCollection>())
		let bid = FindMarketOptions.getBid(tenant:marketplace, address: account.address, marketOption: marketOption, id:id, getNFTInfo:false)
		if bid==nil {
			panic("This bid is on a ghostlisting, so you should cancel the original bid and get your funds back")
		}
	}

	execute {
		self.bidsReference.increaseBid(id: id, increaseBy: amount)
	}
}

