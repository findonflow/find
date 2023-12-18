import FindLeaseMarketSale from "../contracts/FindLeaseMarketSale.cdc"
import FindMarket from "../contracts/FindMarket.cdc"
import FindLeaseMarket from "../contracts/FindLeaseMarket.cdc"

transaction() {
	prepare(account: auth(BorrowValue) &Account) {
		// Get all the saleItems Id

		let tenant = FindMarket.getTenant(FindMarket.getFindTenantAddress())
		let marketOption = FindMarket.getMarketOptionFromType(Type<@FindLeaseMarketSale.SaleItem>())
		let cap = FindLeaseMarket.getSaleItemCollectionCapability(tenantRef: tenant, marketOption: marketOption, address: account.address)
		let ref = cap.borrow() ?? panic("Cannot borrow reference to the capability.")

		let listingType=Type<@FindLeaseMarketSale.SaleItemCollection>()
		let saleItems= account.borrow<&FindLeaseMarketSale.SaleItemCollection>(from: tenant.getStoragePath(listingType))!
		let leases = ref.getNameSales()
		for lease in leases {
			saleItems.delist(lease)
		}
	}
}
