import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"

transaction(leases: [String]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getTenant(FindMarket.getTenantAddress("findLease")!)
		let saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>()))!
		for lease in leases {
			saleItems.delist(lease)
		}

	}
}
