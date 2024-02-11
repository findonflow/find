import "FindMarket"
import "FindLeaseMarketAuctionSoft"

transaction(leaseNames: [String]) {

	let saleItems : auth(FindLeaseMarketAuctionSoft.Seller) &FindLeaseMarketAuctionSoft.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let marketplace = FindMarket.getFindTenantAddress()
		let tenant=FindMarket.getTenant(marketplace)
		self.saleItems= account.storage.borrow<auth(FindLeaseMarketAuctionSoft.Seller) &FindLeaseMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>()))
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
