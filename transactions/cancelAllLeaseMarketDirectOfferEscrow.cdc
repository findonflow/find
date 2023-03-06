import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketDirectOfferEscrow from "../contracts/FindLeaseMarketDirectOfferEscrow.cdc"

transaction() {

	let saleItems : &FindLeaseMarketDirectOfferEscrow.SaleItemCollection?

	prepare(account: AuthAccount) {

		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindLeaseMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketDirectOfferEscrow.SaleItemCollection>()))

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
