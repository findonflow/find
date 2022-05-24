import FindMarketOptions from "../contracts/FindMarketOptions.cdc"
import FindMarketAuctionEscrow from "../contracts/FindMarketAuctionEscrow.cdc"

transaction(marketplace:Address, ids: [UInt64]) {
	prepare(account: AuthAccount) {

		let tenant=FindMarketOptions.getTenant(marketplace)
		let saleItems= account.borrow<&FindMarketAuctionEscrow.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketAuctionEscrow.SaleItemCollection>()))!
		for id in ids {
			saleItems.cancel(id)
		}
	}
}
