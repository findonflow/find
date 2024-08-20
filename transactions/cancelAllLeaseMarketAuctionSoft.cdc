import "FindMarket"
import "FindLeaseMarketAuctionSoft"

transaction() {

	let saleItems : &FindLeaseMarketAuctionSoft.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {
		let leaseMarketplace = FindMarket.getFindTenantAddress()
		let tenant = FindMarket.getTenant(leaseMarketplace)
		self.saleItems= account.storage.borrow<&FindLeaseMarketAuctionSoft.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketAuctionSoft.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to the saleItem."
	}

	execute {
		let leaseNames = self.saleItems!.getNameSales()
		for lease in leaseNames {
			self.saleItems!.cancel(lease)
		}
	}
}
