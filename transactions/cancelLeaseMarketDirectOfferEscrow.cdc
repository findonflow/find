import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"

transaction(leaseNames: [String]) {

	let saleItems : &FindLeaseMarketDirectOfferEscrow.SaleItemCollection?

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>()))

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
