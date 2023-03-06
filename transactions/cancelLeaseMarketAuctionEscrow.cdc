import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"

transaction(leaseNames: [String]) {

	let saleItems : &FindLeaseMarketAuctionEscrow.SaleItemCollection?

	prepare(account: AuthAccount) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.borrow<&FindLeaseMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketAuctionEscrow.SaleItemCollection>()))
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
