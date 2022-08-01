import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(leaseName: String) {

	let market : &FindLeaseMarketDirectOfferSoft.SaleItemCollection
	let pointer : FindLeaseMarket.AuthLeasePointer

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getTenantAddress("findLease")!
		let tenant=FindMarket.getTenant(marketplace)
		let storagePath=tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
		self.market = account.borrow<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: storagePath)!
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>())
		let item = FindLeaseMarket.assertOperationValid(tenant: marketplace, name: leaseName, marketOption: marketOption)
		let ref = account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath) ?? panic("Cannot borrow reference to find lease collection. Account : ".concat(account.address.toString()))
		self.pointer= FindLeaseMarket.AuthLeasePointer(ref: ref, name: leaseName)
	}

	execute {
		self.market.acceptOffer(self.pointer)
	}
}

