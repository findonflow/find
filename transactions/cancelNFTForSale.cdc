import FindMarket from "../contracts/FindMarket.cdc"
import FindMarketSale from "../contracts/FindMarketSale.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"

transaction(id: UInt64) {
	prepare(account: AuthAccount) {
		let tenant=FindMarket.getFindTenant() 
		let saleItems= account.borrow<&FindMarketSale.SaleItemCollection>(from: tenant.getStoragePath(Type<@FindMarketSale.SaleItemCollection>())!)!
		saleItems.delist(id)
	}
}
