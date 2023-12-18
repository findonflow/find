import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction(leaseNames: [String]) {

	let saleItems : &FindLeaseMarketDirectOfferSoft.SaleItemCollection?

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute {
		for leaseName in leaseNames {
			self.saleItems!.cancel(leaseName)
		}
	}
}
