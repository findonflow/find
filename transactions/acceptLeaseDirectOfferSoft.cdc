import "FindLeaseMarketDirectOfferSoft"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FindMarket"
import "FindLeaseMarket"
import "FIND"

transaction(leaseName: String) {

	let market : &FindLeaseMarketDirectOfferSoft.SaleItemCollection
	let pointer : FindLeaseMarket.AuthLeasePointer

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
		self.market = account.storage.borrow<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
		let item = FindLeaseMarket.assertOperationValid(tenant: marketplace, name: leaseName, marketOption: marketOption)
		let ref = account.capabilities.storage.get<auth(FIND.Leasee) &FIND.LeaseCollection>(from: FIND.LeaseStoragePath) ?? panic("Cannot borrow reference to find lease collection. Account : ".concat(account.address.toString()))
		self.pointer= FindLeaseMarket.AuthLeasePointer(ref: ref, name: leaseName)
	}

	execute {
		self.market.acceptOffer(self.pointer)
	}
}

