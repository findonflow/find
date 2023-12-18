import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"

transaction(leases: [String]) {
	let saleItems : &FindLeaseMarketSale.SaleItemCollection?

	prepare(account: auth(BorrowValue) &Account) {

		let tenant=FindMarket.getTenant(FindMarket.getFindTenantAddress())
		self.saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>()))

	}

	pre{
		self.saleItems != nil : "Cannot borrow reference to saleItem"
	}

	execute{
		for lease in leases {
			self.saleItems!.delist(lease)
		}
	}
}
