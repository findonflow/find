import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketDirectOfferEscrow from "../contracts/FindMarketDirectOfferEscrow.cdc"

transaction(id: UInt64) {
	prepare(account: AuthAccount) {

		let tenant=FindMarket.getFindTenantCapability().borrow() ?? panic("Cannot borrow reference to tenant")
		let saleItems= account.borrow<&FindMarketDirectOfferEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketDirectOfferEscrow.SaleItemCollection>())!)!
		saleItems.cancel(id)
	}
}
