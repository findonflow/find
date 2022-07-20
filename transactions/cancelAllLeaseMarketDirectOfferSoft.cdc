import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketDirectOfferSoft from "../contracts/FindLeaseMarketDirectOfferSoft.cdc"

transaction() {

	let saleItems : &FindLeaseMarketDirectOfferSoft.SaleItemCollection?

	prepare(account: AuthAccount) {

		let marketplace = FindMarket.getTenantAddress("findLease")!
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindLeaseMarketDirectOfferSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferSoft.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem."
	}

	execute{
		let nameLeases = self.saleItems!.getNameSales()
		for nameLease in nameLeases {
			self.saleItems!.cancel(nameLease)
		}
	}

}
