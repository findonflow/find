import "FindLeaseMarketDirectOfferSoft"
import "FindMarket"
import "FindLeaseMarket"

transaction(leaseName: String, amount: UFix64) {

	let bidsReference: auth(FindLeaseMarketDirectOfferSoft.Buyer) &FindLeaseMarketDirectOfferSoft.MarketBidCollection

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>())
		self.bidsReference= account.storage.borrow<auth(FindLeaseMarketDirectOfferSoft.Buyer) &FindLeaseMarketDirectOfferSoft.MarketBidCollection>(from: storagePath) ?? panic("Bid resource does not exist")
		// get Bidding Fungible Token Vault
  		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketDirectOfferSoft.MarketBidCollection>())
		let item = FindLeaseMarket.assertBidOperationValid(tenant: marketplace, address: account.address, marketOption: marketOption, name: leaseName)
	}

	execute {
		self.bidsReference.increaseBid(name: leaseName, increaseBy: amount)
	}
}

