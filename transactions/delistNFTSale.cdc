import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"

transaction(marketplace:Address, ids: [UInt64]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketOptions.getTenant(marketplace)
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>()))!
		for id in ids {
			saleItems.delist(id)
		}

	}
}
