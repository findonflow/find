import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketAuctionEscrow from "../contracts/FindLeaseMarketAuctionEscrow.cdc"

transaction() {

	let saleItems : &FindLeaseMarketAuctionEscrow.SaleItemCollection?

	prepare(account: AuthAccount) {
		let leaseMarketplace = FindMarket.getFindTenantAddress()
		let tenant = FindMarket.getTenant(leaseMarketplace)
		self.saleItems= account.borrow<&FindLeaseMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketAuctionEscrow.SaleItemCollection>()))

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
