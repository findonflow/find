import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

transaction(ids: [UInt64]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketTenant.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>()))!
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
