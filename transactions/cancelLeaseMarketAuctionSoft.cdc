import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketAuctionSoft from "../contracts/FindLeaseMarketAuctionSoft.cdc"

transaction(leaseNames: [String]) {

	let saleItems : &FindLeaseMarketAuctionSoft.SaleItemCollection?

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindLeaseMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>()))
	}

	pre{
		self.saleItems != nil
	}

	execute{
		for leaseName in leaseNames {
			self.saleItems!.cancel(leaseName)
		}
	}

}
